#!/usr/bin/env perl

# this script is designed to use core Perl so that non-Perl users can use it
use 5.6.1;    # minimum version for File::Temp
use strict;
use warnings;
use Carp qw(carp croak);
use Getopt::Long;
use File::Temp 'tempfile';

die usage() unless @ARGV;
GetOptions( \my %args, 'database=s', 'table=s', 'sqlite3=s', 'foreign_keys!', )
  or die usage("Bad options");

validate_arguments( \%args );
print build_sql_statements( \%args );

sub build_sql_statements {
    my $arg_for = shift @_;

    my ( $begin_fk, $fk_check, $end_fk ) =
      ( "-- foreign keys were not enabled for $arg_for->{database}", '', '', );
    if ( $arg_for->{foreign_keys} ) {
        $begin_fk = 'PRAGMA foreign_keys = OFF;';
        $fk_check = 'PRAGMA foreign_key_check;';
        $end_fk   = 'PRAGMA foreign_keys = ON;';
    }

    my $sqlite3 = $arg_for->{sqlite3};
    my $db      = $arg_for->{database};
    my $table   = $arg_for->{table};
    my $time    = time;

    my $create    = `$sqlite3 --line $db ".schema $table" 2>/dev/null`;
    my $new_table = "$arg_for->{table}_$time";

    my $create_new = $create;
    $create_new =~ s/\bCREATE\s+TABLE\s+$table\b/CREATE TABLE $new_table/is;

    my $filename = splat( ".mode insert $new_table", "SELECT * FROM $table;" );
    my $copy_old_data_to_new = `$sqlite3 $db --init $filename '.q' 2>/dev/null`;

    return <<"SQL";
$begin_fk
BEGIN;
$fk_check

--
-- Creating our new table
-- Manually change the table here, such as adding a new column
-- 
$create_new

--
-- Manually alter each of these insert statements as needed
--
$copy_old_data_to_new

DROP TABLE $table;
ALTER TABLE $new_table RENAME TO $table;

--
-- If there are any existing triggers, views, or indexes which need to be recreated,
-- do so here
--

COMMIT;
$end_fk
SQL
}

sub validate_arguments {
    my $arg_for = shift @_;

    unless ( exists $arg_for->{sqlite3} ) {

        # Because this is a reference, we are changing the calling value.
        $arg_for->{sqlite3} = 'sqlite3';
    }

    unless ( exists $arg_for->{foreign_keys} ) {
        $arg_for->{foreign_keys} = uses_foreign_keys($arg_for);
    }

    foreach my $required (qw/database table/) {
        croak usage("Missing --$required argument")
          unless $arg_for->{$required};
    }

    unless ( -f $arg_for->{database} ) {
        croak("Database $arg_for->{database} does not exist.");
    }

    unless ( table_exists($arg_for) ) {
        croak(
"Table '$arg_for->{table}' not found in database '$arg_for->{database}'"
        );
    }
}

sub table_exists {
    my $arg_for = shift @_;
    my $sql =
"SELECT name FROM sqlite_master WHERE type='table' AND name='$arg_for->{table}';";
    my $output =
      `$arg_for->{sqlite3} --line $arg_for->{database} "$sql" 2>/dev/null`;
    foreach my $line ( split /\n/, $output ) {
        return 1 if $line =~ /^\s*name = $arg_for->{table}\s*$/;
    }
    return 0;
}

sub uses_foreign_keys {
    my $arg_for = shift @_;
    my $output =
`$arg_for->{sqlite3} --line $arg_for->{database} 'pragma foreign_keys' 2>/dev/null`;
    foreach my $line ( split /\n/, $output ) {
        next unless $line =~ /^foreign_keys = (\d)$/;
        return $1;
    }
    carp(
"Could not determine if $arg_for->{database} uses foreign keys, so we assume it doesn't."
    );
    return 0;
}

sub splat {
    my $text = join "\n", @_;
    my ( $fh, $filename ) = tempfile();
    print $fh $text || croak "Could not print to $filename: $!";
    close $fh || croak "Could not close $filename: $!";
    return $filename;
}

sub usage {
    my $message = shift @_;
    return <<"END";
$message

Usage:

    $0 --database path/to/sqlite/database --table tabletochange > change.sql

See "perldoc $0" for more information and arguments.
END
}

__END__

=head1 NAME

alter_table.pl - Command line tool for generating the stub of an sqlite3 alter table statement

=head1 SYNOPSIS

    bin/alter-table.pl --database db/ovid.db --table articles

=head1 OPTIONS

    OPTION          ARGUMENT                   DESCRIPTION
    database        db filename                Database filename. Required.
    table           db table                   Database table to alter. Required.
    sqlite3         path to sqlite3            Path to executable. Optional. Defaults to "sqlite3" and assumes it's in the $PATH

=head1 DESCRIPTION

B<IMPORTANT>: Because of the way that this script works, if you change any
data in the database I<after> running this script but I<before> applying the
changes from the output, you risk data loss.

SQLite3 is very easy to use, but its C<ALTER TABLE/COLUMN> functionality is
very limited. This script will help with that. It creates an SQL file that you
can easily modify to change your database. In short:

=over 4

=item * Ensure that nothing will change your data until you are done

=item * Back up your SQLite database!

Simply copying it to a backup file is sufficient.

=item * Run this script, redirecting output to a C<$filename>

=item * Verify the SQL in C<$filename> and change the table definition and INSERTs as needed

There are SQL comments in C<$filename> to help you see what you might need to change

=item * Run SQLite, using the new file:

    sqlite3 path/to/db --init $filename

=item * Verify changes, restoring from backup, if needed.

=back

Because the changes in C<$filename> are in a transaction, if there is an issue
that causes the transaction to fail, you can probably just fix C<$filename>
and rerun it.

We use the logic L<as defined on the SQLite web
site|https://www.sqlite.org/lang_altertable.html> to create SQL to make
changing a table easier.

=over 4

=item 1. Disable foreign keys, if needed.

=item 2. Start transaction.

=item 3. Remember indexes, triggers, and views.

Not implemented.

Any constraints on the original table definition will remain.

=item 4. Create a new table with the desired definition

We create a stub of the new table based on the old table. You must manually
alter the C<CREATE TABLE> statement to make the necessary changes.

=item 5. Copy data to temp table

You must manually alter the C<INSERT> statements to make the necessary changes.

=item 6. Drop the original table

=item 7. Rename new table to old table name

=item 8. Any indexes, triggers, or views might need recreating.

Not implemented.

Use CREATE INDEX, CREATE TRIGGER, and CREATE VIEW to reconstruct indexes,
triggers, and views associated with table X. Perhaps use the old format of the
triggers, indexes, and views saved from step 3 above as a guide, making
changes as appropriate for the alteration.

If any views refer to table X in a way that is affected by the schema change,
then drop those views using DROP VIEW and recreate them with whatever changes
are necessary to accommodate the schema change using CREATE VIEW.

See step 3.

=item 9. Commit transaction.

=item 10. Re-enable foreign keys, if necessary.

=back
