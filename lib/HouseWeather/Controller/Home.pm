package HouseWeather::Controller::Home;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw(encode_json);

sub welcome {
	my ($self) = @_;

	my $data = $self->db->all_data();

	$self->stash(all_data => encode_json($data));

	$self->render();
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
