package daemon::DB;

use strict;
use warnings;

use DBI;

sub new {
    my ($class, $dsn_name, $options) = @_;

    my $self = bless({}, $class);
    my $dbh = DBI->connect("dbi:mysql:database=zhao;host=localhost:3306;user=zhaoyao;password=panwujie");
    my $charset = 'utf8';
    $charset = $options->{charset} if $options && $options->{charset};
    $dbh->do("set names $charset");
    $self->{dbh} = $dbh;
    return $self;
}

sub select {
    my ($self, $sql, $bind) = @_;
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute(@$bind);
    return $sth->fetchall_arrayref({});

}

sub select_sth {
    my ($self, $sql, $bind) = @_;
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute(@$bind);
    return $sth;
}

sub select_row {
    my ($self, $sql, $bind) = @_;
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute(@$bind);
    return $sth->fetchrow_hashref();
}

sub select_one {
    my ($self, $sql, $bind) = @_;
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute(@$bind);
    my $row = $sth->fetchrow_arrayref();
    return $row ? $row->[0] : undef;
}

sub execute {
    my ($self, $sql, $bind) = @_;
    my $sth = $self->{dbh}->prepare($sql);
    my $has_error = $sth->execute(@$bind) ? 0 : 1;
    return wantarray ? ($has_error, $sth->errstr) : $has_error;
}

1;
