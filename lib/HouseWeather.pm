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
	$router->get('/query')->to('home#query');
}

1;
