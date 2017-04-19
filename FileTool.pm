package FileTool;
use strict;
use warnings;

use Exporter;
use File::Find qw(find);

our @ISA = qw( Exporter );

our @EXPORT = qw(read_file write_file
                 replace replace_multiple
                 find_replace find_replace_multiple
                 prepend delete_lines
                 flake8_visual_indent flake8_unused_lines);

sub read_file {
    my ($file)= @_;

    open my $in, '<', $file or die "read error: can not open file: $file\n";
    my @lines = <$in>;
    close $in;

    return @lines;
}

sub write_file {
    my ($file, $rlines)= @_;
    my @lines = @$rlines;

    open my $out, '>', $file or die "write error: can not open file: $file\n";
    print $out @lines;
    close $out;
}

sub replace {
    my ($file, $oldstr, $newstr)= @_;
    my @lines = read_file($file);

    # just replace literal text. no regex replacement.
    foreach (@lines) { s/\Q$oldstr\E/$newstr/g; }

    write_file($file, \@lines);
}

sub replace_multiple {
    my ($file, %str_map)= @_;
    my @lines = read_file($file);

    # just replace literal text. no regex replacement.
    foreach my $line (@lines) {
        while (my ($oldstr, $newstr) = each %str_map) {
            $line =~ s/\Q$oldstr\E/$newstr/g;
        }
    }

    write_file($file, \@lines);
}

sub find_replace {
    my ($path, $file_filter, $oldstr, $newstr)= @_;
    find(sub {
            return unless -f $_ && $_ =~ $file_filter;
            replace($_, $oldstr, $newstr);
        }, $path);
}

sub find_replace_multiple {
    my ($path, $file_filter, %str_map)= @_;
    find(sub {
            my $file = $_;
            return unless -f $file && $file =~ $file_filter;
            while (my ($oldstr, $newstr) = each %str_map) {
                replace($file, $oldstr, $newstr);
            }
        }, $path);
}

sub prepend {
    my ($file, $str) = @_;
    my @lines = read_file($file);

    unshift @lines, $str . "\n";

    write_file($file, \@lines);
}

sub delete_lines {
    my ($file, @linenos) = @_;
    my @lines = read_file($file);

    # delete from end lines to begin lines.
    foreach my $lineno (reverse sort @linenos) { splice @lines, $lineno - 1, 1; }

    write_file($file, \@lines);
}

sub indent_pad {
    my($rlines, $lineno, $columnno) = @_;
    my @lines = @$rlines;

    my $current = $lines[$lineno - 1];

    my $paren_count = 0;
    my $paren_columnno = -1;
    my $check_lineno = $lineno - 2; # check from upper lineno
    while ($check_lineno > 0) {
        my $check_line = $lines[$check_lineno];
        my $len = length($check_line);
        for my $i (reverse 0..($len - 1)) {
            my $c = substr $check_line, $i, 1;
            if ($c eq ")") {
                $paren_count ++;
            } elsif ($c eq "(") {
                if ($paren_count == 0) {
                    $paren_columnno = $i;
                    last;
                } else {
                    $paren_count --;
                }
            }
        }
        if ($paren_columnno > -1) {
            last;
        }
        $check_lineno --;
    }
    if ($paren_columnno > -1) {
        # columnno is counting start 1. so munus 1.
        # line up with char after parenthesis, so paren columnno plus 1.
        my $pad = ($columnno - 1) - ($paren_columnno + 1);
        if ($pad > 0) {
            # delete ' ' from the begin of line.
            $current = substr $current, $pad;
        } else {
            # add ' ' to the begin of line.
            $current = (" " x (abs $pad)) . $current;
        }
    }
    $lines[$lineno - 1] = $current;
    return @lines;
}

sub reindent {
    my ($file, %line_columns) = @_;
    my @lines = read_file($file);

    while (my ($lineno, $column) = each %line_columns) {
        @lines = indent_pad(\@lines, $lineno, $column);
    }

    write_file($file, \@lines);
}

sub flake8_visual_indent {
    my ($file_to_check) = @_;
    my @flake8_result = `flake8 $file_to_check`;
    my @greps = grep /continuation line under-indented/, @flake8_result;

    my %file_line_columns = ();
    my ($filename, $lineno, $columm);
    foreach my $grep_line (@greps) {
        next unless $grep_line =~ /(.*?):(\d+):(\d+):/;
        $filename = $1;
        $lineno = $2;
        $columm = $3;
        $file_line_columns{$filename}{$lineno} = $columm;
    }
    for my $file (keys %file_line_columns) {
        my %line_columns = %{ $file_line_columns{$file} };
        reindent($file, %line_columns);
    }
}

sub flake8_unused_lines {
    my ($file_to_check) = @_;
    my @flake8_result = `flake8 $file_to_check`;
    my @greps = grep /imported but unused|redefinition of unused/, @flake8_result;

    my %unused_file_lines = ();
    my ($filename, $lineno);
    foreach my $grep_line (@greps) {
        next unless $grep_line =~ /(.*?):(\d+):/;
        $filename = $1;
        $lineno = $2;
        push @{ $unused_file_lines{$filename} }, $lineno;
    }
    for my $file (keys %unused_file_lines) {
        my @linenos = @{ $unused_file_lines{$file} };
        delete_lines($file, @linenos);
    }
}

1;
