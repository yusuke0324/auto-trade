module ApplicationHelper
  require 'parallel'

  def record_historical_rates(times=3600, interval_sec=1)
    cc = Coincheck.new
    zaif = Zaif.new
    exchange_list = [cc, zaif]

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
    prices = []
    locker = Mutex::new
    # なぜかpricesが更新されない。Rubyはじめて以来の謎
    # Parallel.each(exchanges, in_thread: exchanges.length) do |exchange|
    #   price = exchange.get_price
    #   p 'got price'
    #   p price
    #   locker.synchronize do
    #     p 'adding'
    #     prices << price
    #     p prices
    #   end
    # end
    # when all parallel processes are done, the following process run, thanks!!
    # p prices
    exchanges.each do |exchange|
      prices << exchange.get_price
    end
    sorted_prices = prices.sort{|a, b|
      a[:ask] <=> b[:ask]
    }
    result = {
      low: sorted_prices[0],
      high: sorted_prices[1]
    }
  end

  def get_prices_for_revers(high, low)
    high_price = high.get_price
    low_price = low.get_price
    result = {
      high: high_price,
      low: low_price
    }
  end

  def should_trade?(prices, thresh:300)
    # return wether you should start to trade based on the differences between the two exchanges
    prices[:high][:bid] - prices[:low][:ask] > thresh
  end

  def should_reverse_trade?(prices, dif, thresh:250)
    dif - thresh > prices[:high][:ask] - prices[:low][:bid]
  end

  def normal_order(prices, alpha:1, pair:'btc_jpy', budget:10000)
    # BUY from low, SELL to high
    # BUY--------------------------------
    buy_order = {
      order_type: 'buy',
      pair: pair,
      rate: prices[:low][:ask] + alpha,
      amount: get_target_amount(prices[:low][:ask] + alpha, budget)
    }
    p prices[:low][:exchange].make_new_order(buy_order)
    # SELL----------------------------------
    sell_order = {
      order_type: 'sell',
      pair: pair,
      rate: prices[:high][:bid] - alpha,
      amount: get_target_amount(prices[:high][:bid] - alpha, budget)
    }
    p prices[:high][:exchange].make_new_order(sell_order)
    dif = prices[:high][:bid] - prices[:low][:ask] - 2 *alpha
  end

  def reverse_order(prices, alpha:1, pair:'btc_jpy', budget:10000)
    # SELL to low, BUY from high
    # SELL BACK----------------------------------------
    sell_order = {
      order_type: 'sell',
      pair: pair,
      rate: prices[:low][:bid] - alpha,
      amount: get_target_amount(prices[:low][:bid] - alpha, budget)
    }
    p prices[:low][:exchange].make_new_order(sell_order)

    # BUY BACK-----------------------------------
    buy_order = {
      order_type: 'buy',
      pair: pair,
      rate: prices[:high][:ask] + alpha,
      amount: get_target_amount(prices[:high][:ask] + alpha, budget)
    }
    p prices[:high][:exchange].make_new_order(buy_order)
  end

  def round_trade
    # exchanges init------------
    cc = Coincheck.new
    zaif = Zaif.new
    exchange_list = [cc, zaif]

    # first trade --------------------
    300.times do
      # get low and high
      reverse_flg = false
      prices = get_target_exchanges(exchange_list)
      if should_trade?(prices) then
        dif = normal_order(prices)

    # ERROR hundling (cancel order)-----
        # sleep(10)
        # check_orders
    # seconde trade--------------------
        until reverse_flg
          re_prices = get_prices_for_revers(prices[:high][:exchange], prices[:low][:exchange] )
          reverse_flg = should_reverse_trade?(re_prices, dif)
        sleep(1)
        end
        reverse_order(re_prices)
      end
      sleep(1)
    end
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
    zaif = Zaif.new
    exchange_list = [cc, zaif]
    get_target_exchanges(exchange_list)
  end

  def test2
    total = 0
    list = []

    locker = Mutex::new

    Parallel.each((1..10).to_a, in_threads: 2) do |var|
    # ActiveRecord::Base.connection_pool.with_connection do
      # puts "#{var}番 #{User.find(var).id}"
      # このブロック内は必ず同時に一つのスレッドしか処理しない
      tmp = var
      sleep(1)
      locker.synchronize do
        total += var
        p list << tmp
      end
    # end
    end

    puts total
    p list
    puts "finish!!"
  end
end
