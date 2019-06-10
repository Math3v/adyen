# encoding: UTF-8
require 'test_helper'
require 'nokogiri'
require 'adyen/api'

API_SPEC_INITIALIZER = File.expand_path("../initializer.rb", __FILE__)

if File.exist?(API_SPEC_INITIALIZER)

  describe Adyen::API, "with an actual remote connection" do

    def perform_payment_request
      Adyen::API.authorise_payment(
        @order_id,
        { :currency => 'EUR', :value => '1234' },
        { :email => "#{@user_id}@example.com", :reference => @user_id },
        { :expiry_month => '08', :expiry_year => '2018', :holder_name => "Simon #{@user_id} Hopper", :number => '4111111111111111', :cvc => '737' },
        true
      )
    end

    before :all do
      require API_SPEC_INITIALIZER
      @order_id = @user_id = Time.now.to_i
      @payment_response = perform_payment_request
    end

    it "performs a payment request" do
      skip("test is currently failing because it gets marked as fraud by Adyen")

      @payment_response.must_be :authorized?
      @payment_response.psp_reference.wont_be :empty?
    end

    it "performs a recurring payment request" do
      skip("test is currently failing because it gets marked as fraud by Adyen")

      response = Adyen::API.authorise_recurring_payment(
        @order_id,
        { :currency => 'EUR', :value => '1234' },
        { :email => "#{@user_id}@example.com", :reference => @user_id }
      )
      response.must_be :authorized?
      response.psp_reference.wont_be :empty?
    end

    it "performs a one-click payment request" do
      skip("test is currently failing because it gets marked as fraud by Adyen")

      detail   = Adyen::API.list_recurring_details(@user_id).references.last
      response = Adyen::API.authorise_one_click_payment(
        @order_id,
        { :currency => 'EUR', :value => '1234' },
        { :email => "#{@user_id}@example.com", :reference => @user_id },
        { :cvc => '737' },
        detail
      )
      response.must_be :authorized?
      response.psp_reference.wont_be :empty?
    end

    it "stores the provided ELV account details" do
      response = Adyen::API.store_recurring_token(
        { :email => "#{@user_id}@example.com", :reference => @user_id },
        { :bank_location => "Berlin", :bank_name => "TestBank", :bank_location_id => "12345678", :holder_name => "Simon #{@user_id} Hopper", :number => "1234567890" }
      )
      response.must_be :stored?
      response.recurring_detail_reference.wont_be :empty?
    end

    it "stores the provided creditcard details" do
      response = Adyen::API.store_recurring_token(
        { :email => "#{@user_id}@example.com", :reference => @user_id },
        { :expiry_month => '08', :expiry_year => '2018', :holder_name => "Simon #{@user_id} Hopper", :number => '4111111111111111' }
      )
      response.must_be :stored?
      response.recurring_detail_reference.wont_be :empty?
    end

    it "disables a recurring contract" do
      skip("test is currently failing because it depends on the skipped tests being run")

      response = Adyen::API.disable_recurring_contract(@user_id)
      response.must_be :success?
      response.must_be :disabled?
    end

    it "captures a payment" do
      response = Adyen::API.capture_payment(@payment_response.psp_reference, { :currency => 'EUR', :value => '1234' })
      response.must_be :success?
    end

    it "refunds a payment" do
      response = Adyen::API.refund_payment(@payment_response.psp_reference, { :currency => 'EUR', :value => '1234' })
      response.must_be :success?
    end

    it "cancels or refunds a payment" do
      response = Adyen::API.cancel_or_refund_payment(@payment_response.psp_reference)
      response.must_be :success?
    end

    it "cancels a payment" do
      response = Adyen::API.cancel_payment(@payment_response.psp_reference)
      response.must_be :success?
    end

    it "generates a billet" do
      response = Adyen::API.generate_billet("{\"user_id\":66722,\"order_id\":6863}#signup",
                                            { currency: "BRL", value: 1000 },
                                            { first_name: "Jow", last_name: "Silver" },
                                            "19762003691",
                                            "boletobancario_santander",
                                            "2020-07-16T18:16:11Z",
                                            "free-text billet payment instructions")
      response.must_be :success?
    end
  end

else
  puts "[!] To run the functional tests you'll need to create `spec/functional/initializer.rb' and configure with your test account settings. See `spec/functional/initializer.rb.sample'."
end
