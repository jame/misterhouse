# Category=Music

#@
#@ Jukebox DJ-tested with Winamp/httpq, but should work with all that can respond with now playing info (including elapsed time of course!)  Also lowers and restores player volume during speech.
#@ Requires: mp3 and a player module (ex. mp3_winamp)

#noloop=start
my $trivia_question_asked = 1;
my $trivia_question_answered = 1;
my $dj_flag = ($config_parms{dj})?$config_parms{dj}:1;
my $speech_lowered_volume = 0;
#noloop=stop

$timer_voice_over = new Timer;

$v_dj = new Voice_Cmd('[Start,Stop] the DJ');
$v_dj->set_info('Starts or stops the virtual disc jockey');


$dj_flag = 1 if (said $v_dj eq 'Start');
$dj_flag = 0 if (said $v_dj eq 'Stop');


sub voice_over {
	return if !$dj_flag;
	my $now_playing_formatted;
	my $last_track = shift;
	my $now_playing = &dj_now_playing();	
	my $speech;

	my $mptimestr = &mp3_get_output_timestr();
      
   	my ( $mpelapse, $mprest ) = split ( /\//,$mptimestr );
	my ( $mpmin,  $mpsec ) = split ( /:/,$mpelapse );
	$mpelapse = ( $mpmin * 60 ) + $mpsec ;

	print "DJ Voice over: $last_track-$now_playing-$mpelapse\n"; # if $Debug{dj};


	if ($now_playing ne $last_track and &mp3_playing() and $mpelapse < 7) {

		$now_playing_formatted = format_track($now_playing);

		if ($now_playing_formatted) {
			if (not $trivia_question_asked) {
				my $f_trivia_question = new File_Item("$config_parms{data_dir}/trivia_question.txt");				
				my $trivia_question =  read_all $f_trivia_question;
				$speech = "Time for today's trivia question. $trivia_question";
				$trivia_question_asked = 1;
			}
			elsif ($trivia_question_asked and not $trivia_question_answered) {
				my $f_trivia_answer   = new File_Item("$config_parms{data_dir}/trivia_answer.txt");
				my $trivia_answer =  read_all $f_trivia_answer;
				$speech = "And now the answer to today's trivia question. $trivia_answer";
				$trivia_question_answered = 1;
			}
			elsif (rand(10) > 6) {				
				if (rand(10) > 4) {
					if (time_greater_than("12:00 AM") and time_less_than("12:00 PM")) {
						$speech = "Good morning.";
					}
					elsif (time_greater_than("5:30 AM") and time_less_than("06:00 PM")) {
						$speech = "Good afternoon.";
					}
					elsif (time_greater_than("6:00 PM") and time_less_than("11:59 PM")) {
						$speech = "Good evening.";
					}
					if (rand(10) > 4 and $speech) {
						$speech = " Hey " . $speech;
					}
					$speech .= " The outdoor temperature is " . $Weather{TempOutdoor} . ' ' if (defined $Weather{TempOutdoor});
					$speech .= "inside it is " . $Weather{TempIndoor} . " degrees fahrenheit. " if ($Weather{TempIndoor});
					$speech .= " " . $Weather{chance_of_rain} if ($Weather{chance_of_rain} and rand(10) > 4);
					$speech .= " There is mail in the mailbox." if ($Save{mail_delivered} eq "1" and $Save{mail_retrieved} eq "");

					$speech .= " Tonight is a full moon." if ($Moon{phase} eq 'Full');

			
				}
				$speech .= " Now here's " . $now_playing_formatted;
if (rand(10) > 5) { 
				$speech .= ' on W M H--the voice of Misterhouse';
				$speech .= '.  Keep it right here.' if (rand(10) > 6) ;
			}
			}
			else {
				if (rand(10) > 4) {
					$speech = "That was " . format_track($last_track);
				}
				elsif (rand(10) > 7) {

				        my $conditions;
					$conditions = read_all $f_weather_conditions;


					$speech = "It is $Time_Now";	
					$speech .= $conditions if (rand(10) > 6);
					$speech .= ". In the stock market " . $Save{stock_results} if (rand(10) > 8);
				}
				else {

				        my $conditions;
					$conditions = $Save{weather_forecast};


					$speech = "How are you? It is $Time_Now";	
					$speech .= " and time for the weather forecast. " . $conditions if (rand(10) > 6);
					$speech .= " In the stock market " . $Save{stock_results} if (rand(10) > 8);



				}
				my ($previous_artist) = $last_track =~ /(.+)\s+-\s+(.+)/;
				my ($artist,$title) = $now_playing =~ /(.+)\s+-\s+(.+)/;			
				if ($artist eq $previous_artist) {
					$speech .= ". Now here's another by " . $artist;
				}
				else {
					$speech .= ". Now it's " . $artist . '.';
				}
				if (rand(10) > 5) { 
					$speech .= ' on W M H';
					$speech .= '.  Keep it right here.' if (rand(10) > 6) ;
				}
			}
			
			speak 'app=dj no_chime=1 ' . $speech;
		}
	}
}

sub dj_now_playing {
   my $ref = &mp3_get_playlist();
   my $track;

   if ($ref) {
      my $pos = &mp3_get_playlist_pos();
      if ($pos >= 0) {
         $track = ${$ref}[$pos] if $ref;	 
      } else {
         $track = &mp3_get_curr_song();
      }
   }
   return $track;
}

sub dj {
   my $mptimestr = &mp3_get_output_timestr();

   my $last_track = &dj_now_playing();
      
   my ( $mpelapse, $mprest ) = split ( /\//,$mptimestr );
   my ( $mpmin,  $mpsec ) = split ( /:/,$mpelapse );
   $mpelapse = ( $mpmin * 60 ) + $mpsec ;

   my $mpisrun = &mp3_playing();

   if ($mpisrun) {

   my ( $mptime, $mpperct ) = split ( / /,$mprest ) ;
      ( $mpmin,  $mpsec ) = split ( /:/,$mptime );
   $mptime = ( $mpmin * 60 ) + $mpsec ;


	if ($mptime - $mpelapse > 5) {
		$timer_voice_over->stop() unless inactive $timer_voice_over;
		set $timer_voice_over $mptime - $mpelapse + 1, "voice_over(" . '"' . "$last_track" . '")';	
	}
    }
}

sub format_track {
	my $playing = shift;
	my ($artist,$title) = $playing =~ /(.+)\s+-\s+(.+)/;
	
	if ($artist) {
		return $title . ' by ' . $artist;
	}
} 

&dj() if (new_minute (($config_parms{dj_freq})?$config_parms{dj_freq}:7) or $Reload) and $dj_flag;

# *** This is stupid (should use a time stamp for last time question asked!)

if (new_hour 8) {
	$trivia_question_asked = 0;
	$trivia_question_answered = 0;
}

&Speak_pre_add_hook(\&dj_speech_hook) if $Reload;

sub dj_speech_hook {
    my %parms = &parse_func_parms(@_);

    my $mode = $parms{mode};
    my $app = $parms{app};
	

    #lower volume if speech won't be muted
		# *** Should just combine params above

		if (&mp3_playing() and !$speech_lowered_volume and !$parms{to_file} and $mode ne 'mute') {
			$speech_lowered_volume = 1;

&mp3_control('volume down');
&mp3_control('volume down');

&mp3_control('volume down');
&mp3_control('volume down');


		}	
}

if (state_now $mh_speakers eq OFF) {	

	# *** Need isspeaking check here (for speeches with chimes, volume is raised after sound file ends, not the speech!)

	if ($speech_lowered_volume) {
		for my $i (1..$speech_lowered_volume) {

&mp3_control('volume up');
&mp3_control('volume up');

&mp3_control('volume up');
&mp3_control('volume up');

		}	
	}
	$speech_lowered_volume = 0;
}






