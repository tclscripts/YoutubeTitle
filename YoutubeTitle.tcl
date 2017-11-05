##########################################################################################
# Youtube Title 1.6
# - fetches and displays video information when a YouTube link is posted in channel.
# - displays title, date and rating of posted video links. 
# - supports also HTTPS links.
#
# requires: package http 
#
# UPDATES/CHANGES:
# - Now with multiple output methods of showing the infos configurable via channel
# - Now with multi-language support configurable via channel
# - Now supports eggdrop version less than 1.8.*
# - All options/settings are now case sensitive
#
# To activate .chanset #channel +ytitle | BlackTools : .set +ytitle
#
# To chose a different language .set ytlang <RO> / <EN> / <FR> / <ES> / <IT>
#
# To work put the http.tcl, from the archive, in your eggdrop config (if you don't have it instaled)
#
#                       BLaCkShaDoW ProductionS
#      _   _   _   _   _   _   _   _   _   _   _   _   _   _  
#     / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ 
#    ( t | c | l | s | c | r | i | p | t | s | . | n | e | t )
#     \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/
#                                    #TCL-HELP @ Undernet.org
#     
##########################################################################################

package require http

###
# Bindings
# - using commands
###
bind pubm - * check:youtube
bind ctcp - ACTION check:youtube:me

###
# Channel flags
# - to activate the script: .set +ytitle or .chanset #channel +ytitle
#
# - to change script language:
# .set ytlang <ro/en/fr/es/it> or .chanset #channel ytlang <ro/en/fr/es/it>
#
# - to set script color:
# .set ytcolor <0/1> (1 - colors ; 0 - no colors)
#
###

setudef flag ytitle
setudef str ytlang
setudef str ytcolor

###
# Language setting
# - what language you want to receive the youTube data
#   ( RO / EN / ES / FR / IT )
#
set ytitle(default_lang) "RO"

###
# Colors setting
# - what format you want to receive the youTube data
#   (1) Enable or (0) disable colors
#
set ytitle(colors) "1"

##########################################################################################

###
# Functions
# Do NOT touch unless you know what you are doing
###

proc check:youtube {nick host hand chan arg} {
	
	set arg [split $arg]


if {![channel get $chan ytitle]} {

	return 0
}

foreach word $arg {

	set youtube_link "$word"


if {[string match -nocase "*youtube.com/watch*" $youtube_link] || [string match -nocase "*youtu.be*" $youtube_link]} {

	youtube:get:title $youtube_link $nick $chan

		}
	}
}

proc youtube:get:title {link nick chan} {
	set novideo 0
	set ipq [http::config -useragent "lynx"]
	set ipq [http::geturl "http://youtubesongname.000webhostapp.com/index.php?link=$link" -timeout 50000]
	set getipq [http::data $ipq]
	set output [split $getipq "\n"]
	http::cleanup $ipq
	set title [string map { "&amp;" "&"
			"&#39;" "'"
			"&quot;" "\""
} [lindex $output 0]]
	set title [concat $title]
if {$title == ""} { set novideo 1}
	set views [lindex $output 1]
if {$views == ""} { set views "N/A" }
	set split_views [split $views " "]
	set views [lindex $split_views 0]
	set views [string map {"&nbsp;" "."} $views]
	set likes [lindex $output 2]
	set dontlike [concat [lindex $output 3]]
	set bywho [concat [lindex $output 4]]
	set update [lindex $output 5]
if {$novideo == "1"} {
	youtube:tell $nick $chan 1
	return
}
	set scan [clock scan $update -format {%Y-%m-%d}]
	set update [clock format $scan -format {%d/%m/%Y}]
	
	youtube:tell $nick $chan "$title~$bywho~$views~$likes~$dontlike~$update"

}


proc youtube:tell {nick chan arg} {
	global black ytitle
	set arg_s [split $arg "~"]
	set inc 0
foreach s $arg_s {
	set inc [expr $inc + 1]
	set replace(%msg.$inc%) $s
}
	set getlang [youtube:getlang $chan]
if {$arg == "1"} {
	if {[info exists black(ytitle.$getlang.3)]} {
	set reply [string map [array get replace] $black(ytitle.$getlang.3)]
	putserv "PRIVMSG $chan :$reply"
	}
	return
}
	set setcolor [youtube:getcolor $chan]
if {$setcolor == "1"} {
	set type 2
} else { set type 1 }
if {[info exists black(ytitle.$getlang.$type)]} {
	set reply [string map [array get replace] $black(ytitle.$getlang.$type)]
	putserv "PRIVMSG $chan :$reply"
	}
}

proc youtube:getlang {chan} {
	global black ytitle
	set getlang [string tolower [channel get $chan ytlang]]
if {$getlang == ""} {
	set lang "en"
} else {
if {[info exists black(ytitle.$getlang.1)]} {
	set lang $getlang
} else { 
	set lang $ytitle(default_lang)
		}
	}
	return [string tolower $lang]
}

proc youtube:getcolor {chan} {
	global ytitle
	set getcolor [string tolower [channel get $chan ytcolor]]
if {$getcolor == ""} {
	set type $ytitle(colors)
	} else {
	set type $getcolor
	}
	return $type
}

proc check:youtube:me {nick host hand chan keyword arg} {
check:youtube $nick $host $hand $chan $arg
}

set ytitle(projectName) "Youtube Title"
set ytitle(author) "BLaCkShaDoW"
set ytitle(website) "wWw.TCLScriptS.NeT"
set ytitle(version) "v1.6"

#Languages

# Romanian

set black(ytitle.ro.1) "\002\[YouTube\]\002 Titlu:\002 %msg.1%\002 | Publicat de:\002 %msg.2%\002 | Data:\002 %msg.6%\002 | Vizionari:\002 %msg.3%\002 | Aprecieri:\002 %msg.4%%\002 | Neaprecieri:\002 %msg.5%%\002"
set black(ytitle.ro.2) "\[\002You\0030,4Tube\003\002\003\] \00310Titlu:\0034 %msg.1% \003| \00310Publicat de:\0034 %msg.2% \003| \00310Data:\0034 %msg.6% \003| \00310Vizionari:\0034 %msg.3% \003| \00310Aprecieri:\0034 %msg.4%% \003| \00310Neaprecieri:\0034 %msg.5%%\003"
set black(ytitle.ro.3) "\002\[YouTube\]\002 Acest videoclip nu exista."

# English

set black(ytitle.en.1) "\002\[YouTube\]\002 Title:\002 %msg.1%\002 | Uploaded by:\002 %msg.2%\002 | Date:\002 %msg.6%\002 | Views:\002 %msg.3%\002 | Likes:\002 %msg.4%%\002 | DisLIKEs:\002 %msg.5%%\002"
set black(ytitle.en.2) "\[\002You\0030,4Tube\003\002\003\] \00310Title:\0034 %msg.1% \003| \00310Uploaded by:\0034 %msg.2% \003| \00310Date:\0034 %msg.6% \003| \00310Views:\0034 %msg.3% \003| \00310Likes:\0034 %msg.4%% \003| \00310DisLIKEs:\0034 %msg.5%%\003"
set black(ytitle.en.3) "\002\[YouTube\]\002 This video does not exist."

# French

set black(ytitle.fr.1) "\002\[YouTube\]\002 Titre:\002 %msg.1%\002 | Telecharge par:\002 %msg.2%\002 | La date:\002 %msg.6%\002 | Vues:\002 %msg.3%\002 | J'aime:\002 %msg.4%%\002 | J'aime pas:\002 %msg.5%%\002"
set black(ytitle.fr.2) "\[\002You\0030,4Tube\003\002\003\] \00310Titre:\0034 %msg.1% \003| \00310Telecharge par:\0034 %msg.2% \003| \00310La date:\0034 %msg.6% \003| \00310Vues:\0034 %msg.3% \003| \00310J'aime:\0034 %msg.4%% \003| \00310J'aime pas:\0034 %msg.5%%\003"
set black(ytitle.fr.3) "\002\[YouTube\]\002 Cette video n'existe pas."

# Spanish

set black(ytitle.es.1) "\002\[YouTube\]\002 Titulo:\002 %msg.1%\002 | Cargado por:\002 %msg.2%\002 | Fecha:\002 %msg.6%\002 | Visualizaciones:\002 %msg.3%\002 | Gustos:\002 %msg.4%%\002 | Disgustos:\002 %msg.5%%\002"
set black(ytitle.es.2) "\[\002You\0030,4Tube\003\002\003\] \00310Titulo:\0034 %msg.1% \003| \00310Cargado por:\0034 %msg.2% \003| \00310Fecha:\0034 %msg.6% \003| \00310Visualizaciones:\0034 %msg.3% \003| \00310Gustos:\0034 %msg.4%% \003| \00310Disgustos:\0034 %msg.5%%\003"
set black(ytitle.es.3) "\002\[YouTube\]\002 Este video no existe."

# Italian

set black(ytitle.it.1) "\002\[YouTube\]\002 Titolo:\002 %msg.1%\002 | Caricato da:\002 %msg.2%\002 | Data:\002 %msg.6%\002 | Visualizzazioni:\002 %msg.3%\002 | Piace:\002 %msg.4%%\002 | Non mi piace:\002 %msg.5%%\002"
set black(ytitle.it.2) "\[\002You\0030,4Tube\003\002\003\] \00310Titolo:\0034 %msg.1% \003| \00310Caricato da:\0034 %msg.2% \003| \00310Data:\0034 %msg.6% \003| \00310Visualizzazioni:\0034 %msg.3% \003| \00310Piace:\0034 %msg.4%% \003| \00310Non mi piace:\0034 %msg.5%%\003"
set black(ytitle.it.3) "\002\[YouTube\]\002 Questo video non esiste."

putlog "\002$ytitle(projectName) $ytitle(version)\002 coded by $ytitle(author) ($ytitle(website)): Loaded."

##############
##########################################################
##   END                                                 #
##########################################################
