package Zim::GUI::PathBar;

sub on_path_clicked {
	my ($self, $path, $idx, $path_bar) = @_;
	if ($self->{type} eq 'namespace') {
		my $name = join ':', '', @$path;
		$self->{app}->load_page($name);
	}
	elsif ($self->{type} eq 'history') {
		my $back = $self->{app}{history}->get_state->{back};
		$idx -= $back;
		if    ($idx < 0) { $self->{app}->GoBack(-$idx)   }
		elsif ($idx > 0) { $self->{app}->GoForward($idx) }
		else             { $self->{app}->Reload()        }
	}
	elsif ($self->{type} eq 'recent') {
		my ($name) = @$path;
		my $rec = $self->{app}{history}->jump($name);
		$self->{app}->load_page($rec);
	}
	# else bug
}
1;
