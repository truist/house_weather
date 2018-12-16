package HouseWeather;

use Mojo::Base 'Mojolicious';

use DBI;
use DBD::SQLite;

sub startup {
	my ($self) = @_;

	my $config = $self->plugin('Config');
	$self->{dbh} = $self->init_db($config->{database});

	my $router = $self->routes;
	$router->get('/')->to('home#welcome');
	$router->get('/submit')->to('home#submit');
}

sub init_db {
	my ($self, $config) = @_;

	my $dbh = DBI->connect(
		$config->{dsn}, $config->{username}, $config->{password},
		{ RaiseError => 1, AutoCommit => 1 }
	) or die $DBI::errstr;

	$self->create_data_table($dbh, 'temperature');
	$self->create_data_table($dbh, 'humidity');

	return $dbh;
}

sub create_data_table {
	my ($self, $dbh, $table_name) = @_;

	my $statement = qq|
		CREATE TABLE IF NOT EXISTS $table_name (
			ID        INTEGER  PRIMARY KEY NOT NULL,
			datetime  TEXT     NOT NULL,
			source    TEXT     NOT NULL,
			value     REAL     NOT NULL
		)
	|;
	$dbh->do($statement);
}

1;
