package XML::CSV;

use Text::CSV_XS;
use Carp;

#use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require 5.004;
require Exporter;
#require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter);# DynaLoader);

@EXPORT = qw(
	
);
$VERSION = '0.11';

#bootstrap XML::CSV $VERSION;

my $xml_xs_obj;  #Declared for global usage
my $csvxml_error;  #Error container


sub new($;$)
{
	
	my $class = shift;
	my $attr = shift || {};

	my $self =	{  	'error_out' => 0,
		   		'column_headings' => 0,
		   		'column_data' => 0,
		   		'csv_xs' => 0,
		   		%$attr
			};
		
	bless $self, $class;
	
	if ($attr->{csv_xs})  ### if custom Text::CSV_XS object is provided use it
	{
		$xml_xs_obj = $attr->{csv_xs};
		$attr->{csv_xs} = undef;
	} else {   	      ### else create our own Text::CSV_XS object with it's defaults
		$xml_xs_obj = Text::CSV_XS->new();
	}
	
		
		
	return $self;
	
}

sub parse_doc
{
	my $class = shift;
	my $file_name = shift || croak "Usage: parse_doc(file_name, [\%attr])";
	my $attr = shift;  # %attr (headings, sub_char)
	
	eval {open FILE_CSV, "$file_name";};
	
	$csvxml_error = "Couldn't open file: $file_name.  $@" if $@;
	
	croak "$csvxml_error" if ($class->{'error_out'} == 1 && $@);
				
	my @col_headings;
	
	$attr->{headings} = 0 unless (exists($attr->{headings}));  ### default headings to 0
	
	if ($attr->{headings} == 0)  ### No headings to be used from file
	{
		if ($class->{column_headings})
		{
			@col_headings = @{$class->{column_headings}};   ### if column_heading are provided
		} 			                                ### by user, use them
			
	}
	  			
	my $line;  ### declare $line outside of scope to be use later

	if ($attr->{headings} != 0)
	{		
		$line = <FILE_CSV>;
		my $cols_returned = $get_header->($line, \@col_headings, defined($attr->{sub_char})? $attr->{sub_char}:undef );
		$csvxml_error = "There were no columns returned for headers, please check your CSV file" if (!$cols_returned);
				
		croak "$csvxml_error" if ($class->{'error_out'} == 1);
					
		return 0 if (!$cols_returned);
	}                                                               	
	
	my @arr_cols_data;   ### declare @arr_cols_data to be used for stacking data
	
	while ($line = <FILE_CSV>)
	{
	
 	my @cols_data;
	my $status = $xml_xs_obj->parse($line);  ### parse line by line
	@cols_data = $xml_xs_obj->fields();  ### CSV_XS method returns data array for line passed
	push @arr_cols_data, \@cols_data;    ### stack the returned data
	
	}
	
	$class->{'column_headings'} = \@col_headings;  ### assign reference of @col_headings (xml headers) to object	
	$class->{'column_data'} = \@arr_cols_data;     ### assign reference of @arr_cols_data (xml data) to object

	close FILE_CSV;	

	return 1;
}

sub print_xml
{
	my $class = shift;
	my $file_out = shift || 0;
	my $args = shift || {};  # %attr (file_tag, parent_tag, format)
	
	$args->{file_tag} = "records" unless $args->{file_tag};  #default {parent_tag} to record if not supplied
	$args->{parent_tag} = "record" unless $args->{parent_tag}; 
	$args->{format} = "\t" unless $args->{format};  #default {format} to tab if not supplied
	
	if ($class->{'column_data'} == 0 || ($class->{'column_headings'} == 0 && $class->{'headings'}))
	{
		croak "There is no data to print, make sure that you parsed the document before printing";
	}
	
	###Open file $file_out for output or output to STDOUT
	if ($file_out)
	{
		open FILE_OUT, ">$file_out";
	} else {
		*FILE_OUT = *STDOUT;
	}
	
	print FILE_OUT "<$args->{file_tag}>", "\n";	### print initial document tag
		
	### declare the $tag for <$tag> and $loop_num for headers and data index tracking
	my $tag;
	my $loop_num;

	if ($#{$class->{'column_headings'}} > 0)  ### if column headings are provided
	{
	
		foreach $loop_num (0..$#{$class->{'column_data'}})
		{
			print FILE_OUT $args->{format}, "<$args->{parent_tag}>", "\n";
			foreach $tag (0..$#{$class->{'column_headings'}})
			{
				print FILE_OUT $args->{format}, $args->{format}, "<$class->{'column_headings'}[$tag]>$class->{'column_data'}[$loop_num][$tag]</$class->{'column_headings'}[$tag]>\n";
			}
			print FILE_OUT $args->{format}, "</$args->{parent_tag}>", "\n";
		}
	
	} else {  ### if column headings are not provided we default to $tag
		
		foreach $loop_num (0..$#{$class->{'column_data'}})
		{
	       		print FILE_OUT $args->{format}, "<$args->{parent_tag}>", "\n";
			foreach $tag (0..$#{$class->{'column_data'}->[$loop_num]})
			{
				print FILE_OUT $args->{format}, $args->{format}, "<$tag>$class->{'column_data'}[$loop_num][$tag]</$tag>\n";
			}
			print FILE_OUT $args->{format}, "</$args->{parent_tag}>", "\n";
		}
	}
	
	print FILE_OUT "</$args->{file_tag}>", "\n";  ### print the final document tag
	
	close FILE_OUT;
	
}


$get_header = sub()
{
	my $line = shift;
	my $ref_col = shift;
	my $sub_char = shift;
		
	my $status = $xml_xs_obj->parse($line);
	@$ref_col = $xml_xs_obj->fields();

	if (defined($sub_char))
	{
		map {s/^([^a-zA-Z|_|:]|((x|X)(m|M)(l|L)))/$sub_char/g;} @$ref_col;  #convert all beginning \n or \t or \s to '_'	
		map {s/[^a-zA-Z|^-|^.|^0-9|^:]/$sub_char/g;} @$ref_col;
	}
	
	#print __LINE__.": $ref_col->[0]\n";

	if ($ref_col) {return $#$ref_col;}else{return 0;}
};  

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::CSV - Perl extension converting CSV files to XML

=head1 SYNOPSIS

  use XML::CSV;
  $csv_obj = XML::CSV->new();
  $csv_obj = XML::CSV->new(\%attr);

  $status = $csv_obj->parse_doc(file_name);
  $status = $csv_obj->parse_doc(file_name, \%attr);

  $csv_obj->print_xml(file_name, \%attr);



=head1 DESCRIPTION

XML::CSV is a new module in is going to be upgraded very often as my time permits.
For the time being it uses CSV_XS module object default values to parse the
(*.csv) document and then creates a perl data structure with xml tags names and data.  
At this point it does not allow for a write as you parse interface but is
the first upgrade for the next release.  I will also allow more access to the data structures
and more documentation.  I will also put in more support for XML, since currently
it only allows a simple XML structure.  Currently you can modify the tag structure
to allow for attributes.  No DTD support is currently available, but will be
implemented in a soon coming release.  As the module will provide both: object and event interfaces, it will
be used upon individual needs, system resources, and required performance.  Ofcourse the DOM
implementation takes up more resources and in some instances timing, it's the easiest to use.

=head1 ATTRIBUTES parse_doc()

headings - Specifies the number of rows to use as tag names.  Defaults to 0.
Ex.  {headings => 1} (This will use the first row of data as xml tags)
           
sub_char - Specifies the character with which the illegal tag characters will be
replaced with.  Defaults to undef meaning no substitution is done.  To eliminate
characters use "" (empty string) or to replace with another see below.
Ex.  {sub_char => "_"} or {sub_char => ""}           
           
           
=head1 ATTRIBUTES print_xml()

file_tag - Specifies the file parent tag.  Defaults to "records".
Ex. {file_tag => "file_data"} (Do not use < and > when specifying)

parent_tag - Specifies the record parent tag.  Defaults to "record".
Ex. {parent_tag => "record_data"} (Do not use < and > when specifying)

format - Specifies the character to use to indent nodes.  Defaults to "\t" (tab).
Ex. {format => " "} or {format => "\t\t"}


=head1 EXAMPLES
         

Example #1:

This is a simple implementation which uses defaults

use XML::CSV;
$csv_obj = XML::CSV->new();
$csv_obj->parse_doc("in_file.csv", {headings => 1});

$csv_obj->print_xml("out.xml");

Example #2:

This example uses a passed headings array reference which is used along with the parsed data.

use XML::CSV;
$csv_obj = XML::CSV->new();

$csv_obj->{column_headings} = \@arr_of_headings;

$csv_obj->parse_doc("in_file.csv");
$csv_obj->print_xml("out.xml", {format => " ", file_tag = "xml_file", parent_tag => "record"});


Example #3:

First it passes a reference to a array with column headings and then a reference to two dimensional array
of data where the first index represents the row number and the second column number.  We also pass a custom
Text::CSV_XS object to overwrite the default object.  This is usefull for creating your own CSV_XS object's args
before using the parse_doc() method.  See 'perldoc Text::CSV_XS' for different new() attributes.

use XML::CSV;

$default_obj_xs = Text::CSV_XS->new({quote_char => '"'});
$csv_obj = XML::CSV->new({csv_xs => $default_obj_xs});
$csv_obj->{column_headings} = \@arr_of_headings;

$csv_obj->{column_data} = \@arr_of_data;

$csv_obj->print_xml("out.xml");


=head1 AUTHOR

Ilya Sterin, isterin@mail.com

=head1 SEE ALSO

Text::CSV_XS

=cut
