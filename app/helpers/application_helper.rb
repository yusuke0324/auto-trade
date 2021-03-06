module ApplicationHelper
  require 'parallel'

  def record_historical_rates(times=3600, interval_sec=1)
    cc = Coincheck.new
    zaif = Zaif.new
    # bf = Bitflyer.new

    exchange_list = [cc, bf]

    times.times do
      save_historical_rates_for_exchange_list(exchange_list)
      sleep(interval_sec)
    end

  end

  def save_historical_rates_for_exchange_list(exchange_list)
      exchange_list.each do |exchange|
      price = exchange.get_price
      timestamp = Time.now.to_i.to_s
      rate = Rate.new(
        exchange: price[:exchange].exchange_name,
        bid: price[:bid].to_f,
        ask: price[:ask].to_f,
        time: timestamp
        )
      rate.save
    end
  end

  def get_target_exchanges(exchanges)
    # return target excahnges for a tradem, high and low
    # start_time = Time.now
    prices = []
    locker = Mutex::new
    Parallel.each(exchanges, in_threads: exchanges.length) do |exchange|
      price = exchange.get_price
      locker.synchronize do
        prices << price
      end
    end
    # when all parallel processes are done, the following process run, thanks!!
    # not parallel ver. pararell is about twice faster!
    # exchanges.each do |exchange|
    #   prices << exchange.get_price
    # end
    sorted_prices = prices.sort{|a, b|
      a[:ask] <=> b[:ask]
    }
    result = {
      low: sorted_prices[0],
      high: sorted_prices[1]
    }
    # p "it took #{Time.now - start_time}"
  end

  def test_parallel
    cc = Coincheck.new
    zaif = Zaif.new
    # bf = Bitflyer.new
    exchange_list = [cc, zaif]
    prices = get_target_exchanges(exchange_list)
    p "first get prices #{prices}"
    # re_prices = get_prices_for_reverse(prices[:high][:exchange], prices[:low][:exchange] )
    price_list = [
      {
        id: :high,
        exchange: prices[:high][:exchange]
      },
      {
        id: :low,
        exchange: prices[:low][:exchange]
      },
    ]
    # p re_prices_pal = get_prices_for_reverse_par(price_list)
    # p re_prices = get_prices_for_reverse(prices[:high][:exchange], prices[:low][:exchange])
    start_time = Time.now
    reverse_order(prices, alpha:-10000)
    p "took #{Time.now - start_time}"
  end

#[OLD] this is not parallel ver
  # def get_prices_for_reverse(high, low)
  #   start_time = Time.now
  #   high_price = high.get_price
  #   low_price = low.get_price
  #   result = {
  #       high: high_price,
  #       low: low_price
  #     }
  #   p "NOT parallel it took #{Time.now - start_time}"
  #   result
  # end

  def get_prices_for_reverse(exchange_list)
    # in order to apply multi threads, this method take a list of {
    # id: :high or :low
    # exchange: exchange_obj
  # }
    # start_time = Time.now
    result = {}
    locker = Mutex::new
    Parallel.each(exchange_list, in_threads: exchange_list.length) do |price|
      val = price[:exchange].get_price
      locker.synchronize do
        result[price[:id]] = val
      end
    end
    # p "Parallel it took #{Time.now - start_time}"
    result
  end

  def should_trade?(prices, thresh:300)
    # return wether you should start to trade based on the differences between the two exchanges
    prices[:high][:bid] - prices[:low][:ask] > thresh
  end

  def should_reverse_trade?(prices, dif, thresh:250)
    dif - thresh > prices[:high][:ask] - prices[:low][:bid]
  end

  def get_order_list(prices, low_order, high_order)
    # in order to keep high and low info in multi threads, make a list of a hash which contains id
    normal_order_list = [
      {
        id: :high_order_id,
        exchange: prices[:high][:exchange],
        order: high_order
      },
      {
        id: :low_order_id,
        exchange: prices[:low][:exchange],
        order: low_order
      }
    ]
  end

  def normal_order(prices, alpha:1, pair:'btc_jpy', budget:5000)
    # BUY from low, SELL to high
    # BUY--------------------------------
    buy_order = {
      order_type: 'buy',
      pair: pair,
      rate: prices[:low][:ask] + alpha,
      amount: get_target_amount(prices[:low][:ask] + alpha, budget)
    }
    # not parallel
    # low_order_id =  prices[:low][:exchange].make_new_order(buy_order)[:order_id]
    # SELL----------------------------------
    sell_order = {
      order_type: 'sell',
      pair: pair,
      rate: prices[:high][:bid] - alpha,
      amount: get_target_amount(prices[:high][:bid] - alpha, budget)
    }

    # low -> buy, high -> sell
    normal_order_list = get_order_list(prices, buy_order, sell_order)
    # not parallel
    # high_order_id = prices[:high][:exchange].make_new_order(sell_order)[:order_id]
    dif = prices[:high][:bid] - prices[:low][:ask] - 2 *alpha
    # Parallel process------------------------
    order_ids = parallel_order(normal_order_list)
    return dif, order_ids[:low_order_id], order_ids[:high_order_id]
  end

  def parallel_order(order_list)
    order_ids = {}
    locker = Mutex::new
    Parallel.each(order_list, in_threads: order_list.length) do |order|
      order_id = order[:exchange].make_new_order(order[:order])[:order_id].to_s

      locker.synchronize do
        order_ids[order[:id]] = order_id
      end
    end

    order_ids
  end

  def reverse_order(prices, alpha:1, pair:'btc_jpy', budget:5000)
    # SELL to low, BUY from high
    # SELL BACK----------------------------------------
    sell_order = {
      order_type: 'sell',
      pair: pair,
      rate: prices[:low][:bid] - alpha,
      amount: get_target_amount(prices[:low][:bid] - alpha, budget)
    }
    # low_order_id = prices[:low][:exchange].make_new_order(sell_order)[:order_id]

    # BUY BACK-----------------------------------
    buy_order = {
      order_type: 'buy',
      pair: pair,
      rate: prices[:high][:ask] + alpha,
      amount: get_target_amount(prices[:high][:ask] + alpha, budget)
    }
    # high_order_id = prices[:high][:exchange].make_new_order(buy_order)[:order_id]

    # low -> sell, high -> buy
    reverse_order_list = get_order_list(prices, sell_order, buy_order)
    order_ids = parallel_order(reverse_order_list)

    return order_ids[:low_order_id], order_ids[:high_order_id]
  end

  def check_orders(prices, low_order_id, high_order_id)
    low_close = false
    high_close = false
    cnt = 0
    # until both are closed, check whether they are closed
    until low_close and high_close
      low_close = prices[:low][:exchange].order_closed?(low_order_id)
      high_close = prices[:high][:exchange].order_closed?(high_order_id)
      p low_close, high_close, cnt
      cnt += 1
      sleep(1)
    end
  end

  def test_can_start_trade?
    c = Coincheck.new
    z = Zaif.new
    exchange_list = [c, z]
    can_start_trade?(exchange_list)
  end

  def can_start_trade?(exchange_list, budget=10000)
    # use coincheck as a benchmark
    c = Coincheck.new
    curretn_btc_rate = c.get_price[:ask].to_f
    btc_budget = (budget / curretn_btc_rate).to_f * 1.1
    jpy_budget = budget * 1.1

    exchange_list.each do |exchange|
      if not exchange.has_budget?(jpy_budget, btc_budget)
        return false
      end
    end

    return true
  end

  def test_get_funds_sum
    z = Zaif.new
    c = Coincheck.new
    exchange_list = [z, c]
    funds = get_funds_sum(exchange_list)
  end

  def get_funds_sum(exchange_list, currency_list=['jpy', 'btc'])
    # return obj which contain currecy key and the funds which are collected from all exchanges in the exchange list
    locker = Mutex::new
    balance_list = []

    # init funds obj
    funds = {}
    currency_list.each do |currency|
      funds[currency] = 0
    end
    Parallel.each(exchange_list, in_threads: exchange_list.length) do |exchange|
      balance = exchange.get_balance(currency_list)

      locker.synchronize do
        balance_list << balance
      end
    end

    balance_list.each do |balance|
      balance.each do |k, v|
        funds[k] += v
      end
    end
    funds
  end

  def round_trade(wide_thresh=100, shrink_thresh=50, budget=10000, limit=30, sleep_time=2.5)
    # exchanges init------------
    cc = Coincheck.new
    zaif = Zaif.new
    # bf = Bitflyer.new
    exchange_list = [cc, zaif]
    # check each exchange has enough budget
    if not can_start_trade?(exchange_list, budget)
      p "the exchanges don't have enough deposit!!"
      return
    end
    round_cnt = 0
    sleep(sleep_time)
    # save first all funds for jpy and btc for all exchanges
    prev_funds = get_funds_sum(exchange_list)
    sleep(sleep_time)
    # first trade --------------------
    while round_cnt < limit
      # get low and high
      reverse_flg = false
      prices = get_target_exchanges(exchange_list)
      if should_trade?(prices, thresh: wide_thresh) then
        dif, low_order_id, high_order_id = normal_order(prices, budget: budget)

        check_orders(prices, low_order_id, high_order_id)

    # ERROR hundling (cancel order)-----
        # sleep(10)
        # check_orders
    # seconde trade--------------------
        until reverse_flg
          # this is for multi threads process
          high_low_list = get_high_low_list(prices)
          re_prices = get_prices_for_reverse(high_low_list)
          reverse_flg = should_reverse_trade?(re_prices, dif, thresh: shrink_thresh)
        sleep(sleep_time)
        end
        low_order_id, high_order_id = reverse_order(re_prices, budget: budget)
        check_orders(re_prices, low_order_id, high_order_id)
        sleep(sleep_time)
        curr_funds = get_funds_sum(exchange_list)
    # endo of round trade------------
        p "#{round_cnt} round trades have been completed!"
        p "jpy+: #{curr_funds['jpy'] - prev_funds['jpy']}"
        p "btc+: #{curr_funds['btc'] - prev_funds['btc']}"
        prev_funds = curr_funds
        round_cnt += 1
      end
      sleep(sleep_time)
    end
  end

  def get_high_low_list(prices)
    # in order to keep high and low info in multi threads, make a list of a hash which contains id
    high_low_list = [
      {
        id: :high,
        exchange: prices[:high][:exchange]
      },
      {
        id: :low,
        exchange: prices[:low][:exchange]
      },
    ]
  end

  def reach_minimum_price_unit(price, unit:5, round:'up')
    if price % unit == 0 then
      # nothing to do
      return price
    else
      if round == 'up' then
        # 367 -> 370
        unit - price % unit + price
      elsif round == 'down' then
        # 367 -> 365
        price - price % unit
      end
    end
  end

  def get_target_amount(rate, budget)
    # calculate how much amount can be bought based on the rate and the budget
    target_amount = budget/rate
    # 6.458345 -> 6.45
    BigDecimal(target_amount.to_s).floor(2).to_f
  end

  def test
    cc = Coincheck.new
    # zaif = Zaif.new
    quoine = Quoine.new
    exchange_list = [cc, quoine]
    get_target_exchanges(exchange_list)
  end

  def test_order(obj)
    # b = Bitflyer.new
    order = {
      pair: 'btc_jpy',
      order_type: 'buy',
      rate: 300000,
      amount: 0.01,
    }
    obj.make_new_order(order)
  end

  def get_best_price(price_amount_list, target_amount)
    # return best ask or bid for the amount from the order book info of ask or bid
    # price_amount_list: a list of ['price' , 'amount']
    total_amount = 0
    price_amount_list.each do |price_amount|
      total_amount += price_amount[1].to_f
      if total_amount >= target_amount then
        return price_amount[0].to_f
      end
    end

  end

  def test_get_price_performance
    z = Zaif.new
    c = Coincheck.new
    exchanges = [c, z]
    100.times do
      p get_target_exchanges(exchanges)
      sleep(2)
    end
  end


end
