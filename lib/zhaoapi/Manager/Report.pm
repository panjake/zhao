package zhaoapi::Manager::Report;
use Dancer ':syntax';
use strict;
use warnings;

=pod
This is a minimal example of using Bootstrap's Nav-Bar with embedded login-form.

The <FORM> entry template is "./views/examples/narbar_login.tt".
If the "logged_in" variable is TRUE in the template, the user is considered logged in.

Important note:
This module demonstrates the *Bootstrap* part of navbar+login form.
The dancer implemetation is severely lacking:
1. A proper authentication method should be used.
2. Login should be done over HTTPS (or another protected method)
3. Once the user is logged in, you most likely want to use Dancer's Sessions
   To store the user's information (and make the log-in persistant access
   Dancer calls).

=cut

prefix '/admin';

get '/login' => sub { template 'manager/navbar_login', {}, { layouts => 'main' }; };

post '/login' => sub {
	## Get the <FORM> CGI parameters
	my $username = param 'identifier' ;
	my $password = param 'password' ;

	## Example: if the user submitted invalid data,
	## Show the form again, with a warning.
	## The template file has code that shows a warning <div> if this variable is set.
	$username =~ s/^\s*//;
	$username =~ s/\s*$//;
	if (length($username)==0) {
		return template 'manager/navbar_login' => {
			show_warning => "Missing username",
		};
	}

	# ## do you think this is safe?
	# if ($password ne "12345") {
	# 	return template 'manager/navbar_login' => {
	# 		show_warning => "Wrong username or password",
	# 	};
	# }

	if($username eq 'boss' and $password = 'zhao'){
		return template 'manager/report.tt' => {
			username => $username
		};
	}

	
};

true;
