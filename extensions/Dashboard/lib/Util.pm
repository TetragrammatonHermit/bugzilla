package Bugzilla::Extension::Dashboard::Util;

use strict;
use POSIX qw(strftime);
use Time::Local;
use Bugzilla;
use Bugzilla::Search;
use base qw(Exporter);

use constant {
    SEC_PER_DAY => 86400
};

our @EXPORT = qw(
    open_bugs new_bugs closed_bugs missing_feedback idle_bugs
    new_ports_bugs commit_ports_bugs
);

sub _search {
    my $criteria = shift;
    my $search = new Bugzilla::Search(
        "fields"          => [ "bug_id" ],
        "params"          => $criteria,
        "user"            => Bugzilla->user,
        "allow_unlimited" => 1);

    my $result = $search->data;
    my @buglist = ();
    foreach my $bug (@$result) {
        push(@buglist, $bug->[0]);
    }
    return (scalar(@buglist), \@buglist);
}

sub open_bugs {
    my $product = shift;
    my %criteria = (
        "bug_status" => "__open__",
    );
    if (defined($product)) {
        $criteria{"product"} = $product->name;
    }
    return _search(\%criteria);
}

sub new_bugs {
    my ($product, $days) = @_;

    my $back = time() - ($days * SEC_PER_DAY);
    my $ts = strftime("%Y-%m-%d", localtime($back));

    my %criteria = (
        "bug_status" => "__open__",
        "f1" => "creation_ts",
        "o1" => "greaterthaneq",
        "v1" => $ts
        );
    if (defined($product)) {
        $criteria{"product"} = $product->name;
    }
    return _search(\%criteria);
}

sub closed_bugs {
    my ($product, $days) = @_;

    my $back = time() - ($days * 24 * 60 * 60);
    my $ts = strftime("%Y-%m-%d", localtime($back));

    my %criteria = (
        "bug_status" => "__closed__",
        "f1" => "delta_ts",
        "o1" => "greaterthaneq",
        "v1" => $ts
        );
    if (defined($product)) {
        $criteria{"product"} = $product->name;
    }
    return _search(\%criteria);
}

sub missing_feedback {
    my ($days) = @_;

    my %criteria = (
        "bug_status" => "__open__",
        "f1" => "flagtypes.name",
        "o1" => "substring",
        "v1" => "?",
        "f2" => "days_elapsed",
        "o2" => "greaterthan",
        "v2" => "" . $days
        );
    return _search(\%criteria);
}

sub idle_bugs {
    my ($days) = @_;

    my %criteria = (
        "bug_status" => "__open__",
        "f2" => "days_elapsed",
        "o2" => "greaterthan",
        "v2" => "" . $days
        );
    return _search(\%criteria);
}

sub new_ports_bugs {
    my %criteria = (
        "bug_status" => "New",
        "email1" => "freebsd-ports-bugs\@FreeBSD.org",
        "emailassigned_to1" => "1",
        "emailtype1" => "exact",
        "product" => "Ports Tree",
        "f1" => "longdescs.count",
        "o1" => "equals",
        "v1" => "1"
        );
     return _search(\%criteria);
}

sub commit_ports_bugs {
    my %criteria = (
        "bug_status" => "Patch Ready",
        "email1" => "freebsd-ports-bugs\@FreeBSD.org",
        "emailassigned_to1" => "1",
        "emailtype1" => "exact",
        "product" => "Ports Tree",
        );
     return _search(\%criteria);
}