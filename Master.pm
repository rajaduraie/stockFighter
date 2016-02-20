package Master;

use strict;
use Data::Dumper;
use LWP::UserAgent;
use JSON;
use JSON::Parse 'parse_json';
use v5.16;
use Moose;


has 'base_api' => ( 
		is  => 'ro',
		isa => 'Str',
                required => 1
               );

has 'user_agent' => (
                is => 'ro',
                default => sub {
                  return LWP::UserAgent->new();
                }
               );



sub check_api {
  my $self = shift;
  my $url  = $self->base_api.'heartbeat';
  my $response = $self->user_agent->get($url);
  unless ($response->is_success()) {
    return undef;
  }
  return 1;
}

sub check_venue {
  my ($self, $venue) = @_;
  unless($venue) {
    #$self->log->error('Venue detail missing');
    return undef;
  }
  my $url  = $self->base_api.'venues/'.$venue.'/heartbeat';
  my $req = HTTP::Request->new(GET => $url);
  return $self->retrieve_and_format_response($req);
}

sub get_venue_stocks {
  my ($self, $venue) = @_;
  unless($venue) {
    #$self->log->error('Venue detail missing');
    return undef;
  }
  my $url  = $self->base_api.'venues/'.$venue.'/stocks';
  my $req = HTTP::Request->new(GET => $url);
  return $self->retrieve_and_format_response($req);
}

sub get_order_book {
  my ($self, $venue, $stock) = @_;
  unless($venue && $stock) {
    #$self->log->error('Did not pass required paramaters');
    return undef;
  } 
  my $url = $self->base_api.'venues/'.$venue.'/stocks/'.$stock;
  my $req = HTTP::Request->new(GET => $url);
  return $self->retrieve_and_format_response($req);
}

sub execute_trade {
  my ($self, $order, $api_key) = @_;
  unless($order && $api_key) {
    #$self->log->error('Insufficient details to execute');
    return undef;
  }
  unless(check_order($order)) {
    #$self->log->error('Order validation failed');
    return undef;
  } 

  my $order_json = encode_json($order);

  my $url = $self->base_api.'venues/'.$order->{venue}.'/stocks/'.$order->{symbol}.'/orders';
  my $req = HTTP::Request->new(POST => $url);
  $req->header('X-Stockfighter-Authorization' => "$api_key");

  $req->content($order_json);

  return $self->retrieve_and_format_response($req);
}

sub stock_quote {
  my ($self, $venue, $stock) = @_;
  unless ($venue && $stock) {
    #$self->log->error('Insufficient details to execute');
    return undef;
  }
  my $url = $self->base_api.'/venues/'.$venue.'/stocks/'.$stock.'/quote';
  my $req = HTTP::Request->new(GET => $url);
  return $self->retrieve_and_format_response($req);
}

sub check_order {
  my $order = shift;
  unless (ref($order) eq 'HASH') {
    return undef;
  }
  unless($order->{account} &&
         $order->{venue} &&
         $order->{symbol} &&
         $order->{qty} &&
         $order->{direction} &&
         $order->{orderType}) {
    return undef;
  }
  if ($order->{orderType} ne 'market') {
    return undef unless($order->{price});
  }
  return 1;
}

sub get_order_status {
  my ($self, $id, $venue, $stock, $api_key) = @_;
  unless ($id && $venue && $stock && $api_key) {
    #$self->log->error('Insufficient details to execute');
    return undef;
  }
  my $url = $self->base_api.'venues/'.$venue.'/stocks/'.$stock.'/orders/'.$id;
  my $req = HTTP::Request->new(GET => $url);
  $req->header('X-Stockfighter-Authorization' => "$api_key");

  return $self->retrieve_and_format_response($req);
}

sub cancel_order {
  my ($self, $id, $venue, $stock, $api_key) = @_;
  unless ($id && $venue && $stock && $api_key) {
    #$self->log->error('Insufficient details to execute');
    return undef;
  }
  my $url = $self->base_api.'venues/'.$venue.'/stocks/'.$stock.'/orders/'.$id;
  my $req = HTTP::Request->new(DELETE => $url);
  $req->header('X-Stockfighter-Authorization' => "$api_key");

  return $self->retrieve_and_format_response($req);
}

sub all_order_status {
  my ($self, $venue, $account, $api_key) = @_;
  unless ($venue && $account && $api_key) {
    #$self->log->error('Insufficient details to execute');
    return undef;
  }
  my $url = $self->base_api.'venues/'.$venue.'/accounts/'.$account.'/orders';
  my $req = HTTP::Request->new(GET => $url);
  $req->header('X-Stockfighter-Authorization' => "$api_key");

  return $self->retrieve_and_format_response($req);
}

sub all_orders_for_stock {
  my ($self, $venue, $account, $stock, $api_key) = @_;
  unless ($venue && $account && $stock && $api_key) {
    #$self->log->error('Insufficient details to execute');
    return undef;
  }
  my $url = $self->base_api.'venues/'.$venue.'/accounts/'.$account.'/stocks/'.$stock.'/orders';
  my $req = HTTP::Request->new(GET => $url);
  $req->header('X-Stockfighter-Authorization' => "$api_key");
  return $self->retrieve_and_format_response($req);
}

sub retrieve_and_format_response {
  my ($self, $request) = @_;
  my $response = $self->user_agent->request($request);
  unless($response->is_success()){
    #$self->log->error($response->decoded_content());
    return undef;
  }
  return parse_json($response->decoded_content());
}
1;
