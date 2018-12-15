package HouseWeather;
use Mojo::Base 'Mojolicious';

sub startup {
	my ($self) = @_;

	my $config = $self->plugin('Config');

	my $router = $self->routes;
	$router->get('/')->to('home#welcome');
}

1;
