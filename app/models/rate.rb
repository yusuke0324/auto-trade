class Rate < ApplicationRecord
  require 'csv'

  def to_csv(file_name='file_name')
    all = Rate.all
    csv_string = CSV.generate(:force_quotes => true) do |csv|
      # csv headers
      csv << ['exchange', 'bid', 'ask', 'time', 'created_at']
      all.each do |row|

        csv <<[
          row[:exchange],
          row[:bid],
          row[:ask],
          row[:time],
          row[:created_at]
        ]
      end

    end

    File.open(file_name + '.csv', 'w', encoding:'utf-8', undef: :replace) do |file|
      file.write(csv_string)
    end
  end
end
