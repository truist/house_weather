package HouseWeather::Controller::Home;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw(encode_json);
use Mojo::UserAgent;
use Mojo::URL;

sub welcome {
	my ($self) = @_;

	$self->render();
}

sub submit {
	my ($self) = @_;

	my $source = $self->_get_required_param('source');
	my $temp = $self->_get_required_param('temperature');
	my $humidity = $self->_get_required_param('humidity');

	$self->db->add_record($source, $temp, $humidity);

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
		$self->db->add_record($zip, $temp, $humidity);

		$self->render(text => "Temp: $temp; humidity: $humidity");
	} else {
		$self->render(text => $result->message);
	}
}

sub query {
	my ($self) = @_;

	$self->render(json => $self->db->all_data());
}

sub _get_required_param {
	my ($self, $name) = @_;

	my $value = $self->param($name) or die "Argument '$name' is requred";
	return $value;
}

1;
