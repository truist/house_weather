package HouseWeather;

use Mojo::Base 'Mojolicious';

use DB;

sub startup {
	my ($self) = @_;

	my $config = $self->plugin('Config');
	$self->secrets($config->{secrets});

	$self->helper(db => sub { state $db = DB->init($config) });

	my $router = $self->routes;
	$router->get('/')->to('home#welcome');
	$router->any(['GET', 'POST'] => '/submit')->to('home#submit');
	$router->any(['GET', 'POST'] => '/water')->to('home#water');
	$router->any(['GET', 'POST'] => '/electricity')->to('home#electricity');
	$router->get('/query')->to('home#query');
	$router->get('/outside')->to('home#log_outside_weather');
}

1;
