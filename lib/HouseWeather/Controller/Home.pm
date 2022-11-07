package HouseWeather::Controller::Home;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw(encode_json);
use Mojo::UserAgent;
use Mojo::URL;

use DateTime;
use DateTime::Duration;

sub welcome {
  my ($self) = @_;

  my $last = $self->param('last') || '2days';
  my ($length, $units) = $last =~ /^(\d+)(minutes?|hours?|days?|weeks?|months?|years?)$/;
  if ($units) {
    $units .= 's' unless $units =~ /s$/;
    $self->stash('body_class' => $units.$length);
    $self->stash('start' => DateTime->now()->subtract(DateTime::Duration->new($units => $length)));
  } else {
    $self->stash('body_class' => 'unknown');
    $self->stash('start' => undef);
  }

  $self->render();
}

sub submit {
  my ($self) = @_;

  my $source = $self->_get_required_param('source');

  my $temp = $self->param('temperature') || undef;

  my $humidity = $self->param('humidity') || undef;

  my $co2 = $self->param('co2') || undef;
  my $voc = $self->param('voc') || undef;
  my $pm25 = $self->param('pm25') || undef;

  $self->_normalize_and_save($source, $temp, $humidity, $co2, $voc, $pm25);

  $self->render(text => 'OK');
}

sub log_outside_weather {
  my ($self) = @_;

  my $zip = $self->_get_required_param('zip');

  my $url = Mojo::URL->new('https://api.openweathermap.org/data/2.5/weather');
  $url->query({zip => "$zip,us", appid => $self->config->{openweathermap_api_key}});

  my $result = Mojo::UserAgent->new()->get($url)->result();
  if ($result->is_success) {
    my $data = $result->json->{main};

    my $temp = sprintf("%.1f", $data->{temp} - 273.15);
    my $humidity = $data->{humidity};

    $self->_normalize_and_save($zip, $temp, $humidity);

    $self->render(text => "Temp: $temp; humidity: $humidity");
  } else {
    $self->render(text => $result->message);
  }
}

sub query {
  my ($self) = @_;

  my $results = $self->db->query($self->param('start'));
  say("DB query results: " . scalar(@$results));
  $self->render(json => $results);
}

sub _normalize_and_save {
  my ($self, $source, $temp, $humidity, $co2, $voc, $pm25) = @_;

  no warnings 'uninitialized';
  say("source: $source; temp: $temp; humidity: $humidity; co2: $co2; voc: $voc; pm25: $pm25;");

  if ($temp < -30 || $temp > 50) {
    $temp = undef;
  }
  if ($humidity < 0 || $humidity > 100) {
    $humidity = undef;
  }

  $self->db->add_air_record($source, $temp, $humidity, $co2, $voc, $pm25);
}

sub _get_required_param {
  my ($self, $name) = @_;

  my $value = $self->param($name) or die "Argument '$name' is requred";
  return $value;
}

1;
