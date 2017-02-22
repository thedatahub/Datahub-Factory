package Datahub::Factory::Fixer::Merge;

use strict;
use warnings;

use Moo;
use Catmandu;

use Hash::Merge qw(merge);

# Must be in the same format
has left_record  => (is => 'ro');
has right_record => (is => 'ro'); # Right record takes precedence

#RETAINMENT_PRECEDENT ?
Hash::Merge::set_behavior('RIGHT_PRECEDENT');

has merged_record => (is => 'lazy');

sub _build_merged_record {
    my $self = shift;
    my $merged = merge($self->left_record, $self->right_record);
    return $merged;
}

1;
__END__