# -*- perl -*-

require 5.004;


BEGIN { $| = 1; print "1..3\n"; }
END {print "Did not pass all tests" unless $loaded;}
use XML::CSV;

print "Loaded OK\n";
$loaded = 1;


eval{
my $obj = XML::CSV->new();
my $num = $obj->parse_doc("data1.csv", {'headings' => 1});
$obj->print_xml("test1.xml");
};

if($@)
{
print "not ok 1: $@\n";
$loaded = 0;
undef($@);
} else {	
print "ok 1\n";
}




##########################################

eval{
$csv_obj = XML::CSV->new();
@arr_of_headings = ('one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven');
$csv_obj->{column_headings} = \@arr_of_headings;
$csv_obj->parse_doc("data1.csv");
$csv_obj->print_xml("out.xml");
};

if($@)
{
print "not ok 2: $@\n";
$loaded = 0;
undef($@);
} else {	
print "ok 2\n";
}




##########################################

eval{
$default_obj_xs = Text::CSV_XS->new({quote_char => '"'});
$csv_obj = XML::CSV->new({csv_xs => $default_obj_xs});
$csv_obj->{column_headings} = \@arr_of_headings;

$csv_obj->{column_data} = \@arr_of_data;

$csv_obj->print_xml("out.xml");
};

if($@)
{
print "not ok 3: $@\n";
$loaded = 0;
undef($@);
} else {	
print "ok 3\n";
}


