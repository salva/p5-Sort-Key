use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Sort::Key',
	       VERSION_FROM  => 'lib/Sort/Key.pm',
	       PREREQ_PM     => { 'Test::More' => 0.54 },
	       ABSTRACT_FROM => 'lib/Sort/Key.pm',
	       AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
	       LIBS          => [''],
	       DEFINE        => '',
	       INC           => '-I.' );
