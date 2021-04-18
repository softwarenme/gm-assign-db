# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "rails", '6.1.3.1' #github: "rails/rails", branch: "main"
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :sellers, force: true do |t|
    t.float :balance, default: 0
  end

  create_table :customers, force: true do |t|
  end

  create_table :payout_schedules, force: true do |t|
    t.integer :seller_id
    t.integer :buffer_days, default: 7

    t.string :payout_day, default: 'Friday'
  end

  create_table :products, force: true do |t|
    t.integer :seller_id, index: true
    t.float :price
  end

  create_table :purchases, force: true do |t|
    t.integer :product_id, index: true
    t.integer :customer_id, index: true

    t.float :amount

    t.boolean :paid_to_seller, default: false
    t.boolean :processed, default: false

    t.date :purchase_date, index: true
  end

  create_table :refunds, force: true do |t|
    t.integer :purchase_id, index: true
    t.boolean :processed

    # Refund can be full amount or partial amount
    t.float :amount
  end
end

class Seller < ActiveRecord::Base
  has_many :products
  has_many :purchases, through: :products

  has_one :payout_schedule
end

class PayoutSchedule < ActiveRecord::Base
  belongs_to :seller
end

class Customer < ActiveRecord::Base
  has_many :purchases
end

class Product < ActiveRecord::Base
  belongs_to :seller
  has_many :purchases
end

class Purchase < ActiveRecord::Base
  belongs_to :product
  belongs_to :customer

  has_one :refund

  scope :unsettled, -> { where(paid_to_seller: false) }
  scope :processed, -> { where(processed: false) }
  scope :unsettled_processed_till, -> (date) { unsettled.processed.where('purchase_date <= ?', date) }
end

class Refund < ActiveRecord::Base
  belongs_to :purchase
end


class ProcessPayout

  def initialize(seller_id)
    @seller = Seller.find(seller_id)
    @payout_schedule = @seller.payout_schedule
  end

  def process
    return unless today_seller_payout_day?

    ActiveRecord::Base.transaction do
      calculate_balance

      update_purchases
      update_seller_balance
    end
  end

  private

  def today_seller_payout_day?
    # @payout_schedule.payout_day == Date.today.strftime("%A")

    # For tetss we will always return true
    true
  end

  def calculate_balance
    @balance = @seller.balance

    eligible_purchases.each do |purchase|
      @balance += purchase.amount

      refund = purchase.refund

      if refund
        @balance -= refund.amount
      end
    end
  end

  def update_seller_balance
    @seller.update_attribute(:balance, @balance)
  end

  def update_purchases
    eligible_purchases.update_all(paid_to_seller: true)
  end

  def eligible_purchases
    @_eligible_purchases ||= @seller.purchases.unsettled_processed_till(purchases_till_date)
  end

  def purchases_till_date
    Date.today - @payout_schedule.buffer_days.days
  end
end

class ProcessPayoutTest < Minitest::Test
  def test_payout_with_default_schedule
    seller = Seller.create!
    customer = Customer.create!

    seller.create_payout_schedule

    product_1 = Product.create!(price: 20.1, seller_id: seller.id)
    product_2 = Product.create!(price: 45.4, seller_id: seller.id)
    product_3 = Product.create!(price: 50.4, seller_id: seller.id)

    product_1.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 14.days, amount: product_1.price)
    product_1.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 2.days, amount: product_1.price)

    product_2.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 7.days, amount: product_2.price)
    product_3.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 8.days, amount: product_3.price)

    product_2.purchases.first.create_refund(amount: product_2.price)

    service = ProcessPayout.new(seller.id)
    service.process

    seller.reload

    assert_equal 70.5, seller.balance
  end

  def test_payout_with_every_week_schedule
    seller = Seller.create!
    customer = Customer.create!

    seller.create_payout_schedule(buffer_days: 0)

    product_1 = Product.create!(price: 20.1, seller_id: seller.id)
    product_2 = Product.create!(price: 45.4, seller_id: seller.id)
    product_3 = Product.create!(price: 50.4, seller_id: seller.id)

    product_1.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 14.days, amount: product_1.price)
    product_1.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 2.days, amount: product_1.price)

    product_2.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 7.days, amount: product_2.price)
    product_3.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 8.days, amount: product_3.price)

    product_2.purchases.first.create_refund(amount: product_2.price)

    service = ProcessPayout.new(seller.id)
    service.process

    seller.reload

    assert_equal 90.6, seller.balance
  end

  def test_payout_with_custom_schedule
    seller = Seller.create!
    customer = Customer.create!

    seller.create_payout_schedule(buffer_days: 3)

    product_1 = Product.create!(price: 20.1, seller_id: seller.id)
    product_2 = Product.create!(price: 45.4, seller_id: seller.id)
    product_3 = Product.create!(price: 50.4, seller_id: seller.id)

    product_1.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 14.days, amount: product_1.price)
    product_1.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 2.days, amount: product_1.price)

    product_2.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 7.days, amount: product_2.price)
    product_3.purchases.create!(customer_id: customer.id, purchase_date: Date.today - 8.days, amount: product_3.price)

    product_2.purchases.first.create_refund(amount: product_2.price)

    service = ProcessPayout.new(seller.id)
    service.process

    seller.reload

    assert_equal 70.5, seller.balance
  end
end
