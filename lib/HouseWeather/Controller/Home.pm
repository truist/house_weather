package HouseWeather::Controller::Home;
use Mojo::Base 'Mojolicious::Controller';

sub welcome {
	my ($self) = @_;

	$self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

1;
