package HouseWeather::Controller::Home;
use Mojo::Base 'Mojolicious::Controller';

sub welcome {
	my ($self) = @_;

	$self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub submit {
	my ($self) = @_;

	my $source = $self->get_required_param('source');
	my $temp = $self->get_required_param('temperature');
	my $humidity = $self->get_required_param('humidity');

	$self->db->add_record($source, $temp, $humidity);

	$self->render(text => 'OK');
}

sub get_required_param {
	my ($self, $name) = @_;

	my $value = $self->param($name) or die "Argument '$name' is requred";
	return $value;
}

1;
