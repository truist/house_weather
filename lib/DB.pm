package DB;

use strict;
use warnings;
use v5.10;

use DBI;
use DBD::SQLite;

my $TABLE_NAME = 'data';

my $ID_COL = 'ID';
my $DATE_COL = 'datetime';
my $SOURCE_COL = 'source';
my $TEMP_COL = 'temp';
my $HUMIDITY_COL = 'humidity';

sub init {
	my ($package, $config) = @_;

	my $dbh = DBI->connect(
		'DBI:SQLite:dbname=' . $config->{db_file},
		undef, undef,
		{ RaiseError => 1, AutoCommit => 1 }
	) or die $DBI::errstr;

	my $statement = qq|
		CREATE TABLE IF NOT EXISTS $TABLE_NAME (
			$ID_COL        INTEGER  PRIMARY KEY NOT NULL,
			$DATE_COL      TEXT     NOT NULL,
			$SOURCE_COL    TEXT     NOT NULL,
			$TEMP_COL      REAL     NOT NULL,
			$HUMIDITY_COL  REAL     NOT NULL
		)
	|;
	$dbh->do($statement);

	my $self = bless({}, $package);
	$self->{dbh} = $dbh;

	return $self;
}

sub add_record {
	my ($self, $source, $temp, $humidity) = @_;

	my $statement = qq|
		INSERT INTO $TABLE_NAME (
			$DATE_COL,
			$SOURCE_COL, $TEMP_COL, $HUMIDITY_COL
		) VALUES (
			DATETIME('now'),
			?, ?, ?
		)
	|;
	$self->{dbh}->do($statement, undef, $source, $temp, $humidity);
}

sub all_data {
	my ($self) = @_;

	my $statement = qq|
		SELECT $DATE_COL, $SOURCE_COL, $TEMP_COL, $HUMIDITY_COL
		FROM $TABLE_NAME
	|;
	return $self->{dbh}->selectall_arrayref($statement, { Slice => {} });
}

1;
