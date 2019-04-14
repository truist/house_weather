package HouseWeather::Controller::Home;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw(encode_json);
use Mojo::UserAgent;
use Mojo::URL;

use DateTime;
use DateTime::Duration;

sub welcome {
	my ($self) = @_;

	my $last = $self->param('last') || '1week';
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
	my $temp = $self->_get_required_param('temperature');
	my $humidity = $self->_get_required_param('humidity');

	$self->_add_record_if_valid($source, $temp, $humidity);

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

		$self->_add_record_if_valid($zip, $temp, $humidity);

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

sub _add_record_if_valid {
	my ($self, $source, $temp, $humidity) = @_;

	say("source: $source; temp: $temp; humidity: $humidity");
	if ($temp > -30 && $temp < 50 && $humidity >= 0 && $humidity <= 100) {
		$self->db->add_record($source, $temp, $humidity);
	}
}

sub _get_required_param {
	my ($self, $name) = @_;

	my $value = $self->param($name) or die "Argument '$name' is requred";
	return $value;
}

1;
