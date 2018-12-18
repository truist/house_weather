package HouseWeather::Controller::Home;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw(encode_json);

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
