use v5.16;
use Master;
use Data::Dumper;

my ($exchange, $account, $stock, $no_of_shares, $chunk_size, $api_key) = @ARGV;

my $client = Master->new( base_api => 'https://api.stockfighter.io/ob/api/');

my $bought = 0;
while($bought < $no_of_shares) {
  my $stock_quote_resp = $client->stock_quote($exchange, $stock);
  unless($stock_quote_resp) {
    print Dumper($stock_quote_resp);
    die "Error while querying exchange. Will terminate";
  }
  #Warning - In real world, this could create a competing set of bids with other bots
  my $quote = $stock_quote_resp->{ask}; 
  unless($quote) {
    $stock_quote_resp = $client->stock_quote($exchange, $stock);
    unless($stock_quote_resp) {
      die "Error while querying exchange. Will terminate";
    }
    $quote = $stock_quote_resp->{ask}; 
  }
  $chunk_size += 0;
  $quote += 0;
  my $order = {
    "account" => $account,
    "venue" => $exchange,
    "symbol" => $stock,
    "price" => $quote,
    "qty" => $chunk_size,
    "direction" => "buy",
    "orderType" => "limit"
  };

  my $execute_response = $client->execute_trade($order, $api_key);
  unless($execute_response) {
    say Dumper($execute_response);
    #die "Terminated due to error";
  } else {
    my $filled = $execute_response->{totalFilled};
    my $order_id = $execute_response->{id};
    my $original_qty = $execute_response->{originalQty};


    while ($filled < $original_qty) {
      sleep 2;
      my $order_check_reponse = $client->get_order_status($order_id, $exchange, $stock,$api_key);
      $filled = $order_check_reponse->{totalFilled};
    }
    
    $bought += $filled;
    say "$bought have been bought out of $no_of_shares";
  }
} 

 
