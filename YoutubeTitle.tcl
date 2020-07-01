##########################################################################################
# Youtube Title 2.2
# - fetches and displays video information when a YouTube link is posted in channel.
# - displays title, date and rating of posted video links.
# - supports also HTTPS links.
#
# requires: packages http, tls
#
# UPDATES/CHANGES:
# - (2.2) added german language
# - (2.2) solved some little bugs
# - (2.2) solved issues related to youtube changes
# - (2.1) solved issue with youtube live videos
# - (2.0) now the script access directly Youtube
# - (1.9) added stars for like display instead of procentages
# - (1.8) added anti-flood support
# - (1.8) added youtube search (it will get info from the first youtube video)
# - (1.8) added support for music.youtube links
# - (1.8) shows total links/searches processed by the website
# - (1.7) shows info about duration/length
# - (1.6) multiple output methods of showing the infos configurable via channel
# - (1.6) multi-language support configurable via channel
# - (1.6) supports eggdrop version less than 1.8.*
# - (1.6) options/settings are now case sensitive
#
# To activate - .chanset #channel +ytitle | BlackTools : .set +ytitle
# To activate Youtube search - .chanset #channel +ytsearch | BlackTools : .set +ytsearch
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

###
# Channel flags
# - to activate the script: .set +ytitle or .chanset #channel +ytitle
#
# - to change script language:
# .set ytlang <ro/en/fr/es/it> or .chanset #channel ytlang <ro/en/fr/es/it>
#
# - to set script color
# .set ytcolor <0/1> ; 1 - colors ; 0 - no colors
#
###

###
# YOUTUBE SEARCH COMMAND
#
###
set ytitle(youtube_search_cmd) "yt"

###
# WHAT FLAGS CAN SEARCH VIA COMMAND ? (default -|-)
#
###

set ytitle(youtube_search_flags) "-|-"

###
# FLOOD PROTECTION
#Set the number of minute(s) to ignore flooders, 0 to disable flood protection
###
set ytitle(ignore_prot) "1"

###
# FLOOD PROTECTION
#Set the number of requests within specifide number of seconds to trigger flood protection.
# By default, 3:10, which allows for upto 3 queries in 10 seconds. 3 or more quries in 10 seconds would cuase
# the forth and later queries to be ignored for the amount of time specifide above.
###
set ytitle(flood_prot) "3:10"

###
# Language setting
# - what language you want to receive the youTube data
#   ( RO / EN / ES / FR / IT / DE )
#
set ytitle(default_lang) "DE"

###
# Colors setting
# - what format you want to receive the youTube data
#   (1) Enable or (0) disable colors
#
set ytitle(colors) "0"

##########################################################################################

package require http
package require tls

###
# Bindings
# - using commands
###
bind pubm - * check:youtube
bind ctcp - ACTION check:youtube:me
bind pub $ytitle(youtube_search_flags) $ytitle(youtube_search_cmd) search:youtube

setudef flag ytitle
setudef str ytlang
setudef str ytcolor
setudef flag ytsearch


###
# Functions
# Do NOT touch unless you know what you are doing
###

	set counter_link "ytitle_link_counter"
if {![file exists $counter_link]} {
	set file [open $counter_link w]
	puts $file "0"
	close $file
}

###
proc ytitle:counter {} {
	global ytitle counter_link
	set file [open $counter_link r]
	set read_it [read -nonewline $file]
	close $file
	set incr_num [expr $read_it + 1]
	set file [open $counter_link w]
	puts $file $incr_num
	close $file
	return $incr_num
}

###
proc tls:socket args {
   set opts [lrange $args 0 end-2]
   set host [lindex $args end-1]
   set port [lindex $args end]
   ::tls::socket -servername $host {*}$opts $host $port
}

###
proc ytitle:get_idsearch {arg} {
	global ytitle
	set text [join $arg "+"]
	set search_query [::http::formatQuery search_query $text]
	set url "https://www.youtube.com/results?$search_query"
	set id "-1"
	http::register https 443 tls::socket
	set ipq [http::config -useragent "lynx"]
	set ipq [::http::geturl "$url" -timeout 30000]
	set status [http::status $ipq]
if {$status != "ok"} {
	::http::cleanup $ipq
	return 0
}
	set data [http::data $ipq]
	regexp {<li><div class="yt-lockup yt-lockup-tile yt-lockup-video vve-check clearfix" data-context-item-id="(.*)"} $data -> id
if {$id == -1} {
	regexp {\[\{\"videoRenderer\"\:\{\"videoId\"\:\"(.*?)\"} $data -> id
}
if {$id == "-1"} {
	return 0
}
	return [string map {"\"" ""} [lindex [split $id] 0]]
}

###
proc ytitle:data {link} {
	global ytitle
	set valid_link [regexp {(?:youtube(?:-nocookie)?\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})} $link -> id]
if {![info exists id]} {
	return 0
}
	set url "https://www.youtube.com/watch?v=$id"
	set short_url "https://youtu.be/$id"
	http::register https 443 tls::socket
	set ipq [http::config -useragent "lynx"]
	set ipq [::http::geturl "$url" -timeout 30000]
	set status [http::status $ipq]
if {$status != "ok"} {
	::http::cleanup $ipq
	return 0
}
	set link_counter [ytitle:counter]
	set data [split [http::data $ipq] "\n"]
	set title ""
	set date ""
	set view_count ""
	set likes ""
	set dislikes ""
	set bywho ""
	set duration ""
	set tools ""
	set type 0
foreach line $data {
	regexp {"name": "(.*)"} $line -> bywho
	regexp {<span id="eow-title" class="watch-title" dir="ltr" title="(.*)">} $line -> title
if {$title == ""} {
	regexp {<meta name="title" content="(.*)">} $line -> title
}
	regexp {<meta itemprop="datePublished" content="(.*)">} $line -> date
	regexp {<div class="watch-view-count">(.*)</div>} $line -> view_count
if {$view_count == ""} {
	regexp {\"viewCount\":\{\"simpleText\":\"(.*?)\"\}} $line -> view_count
	regexp {\"likeStatus\":\"INDIFFERENT\"\,\"tooltip\"\:\"(.*?)\"\}\}} $line -> tools
if {$tools != ""} {
	set type 1
}
	set split_tools [split $tools "/"]
	set likes [string map {"." ""} [concat [lindex $split_tools 0]]]
	set dislikes [string map {"." ""} [concat [lindex $split_tools 1]]]
} else {
	regexp {<div class="video-extras-sparkbar-likes" style="width:(.*)"></div>} $line -> likes
	regexp {div class="video-extras-sparkbar-dislikes" style="width:(.*)"><\/div>} $line -> dislikes
	set likes [concat $likes]
	set dislikes [concat $dislikes]
	set view_count [lindex [split $view_count " "] 0]
}
	regexp {<meta itemprop="duration" content="(.*)">} $line -> duration
}
	::http::cleanup $ipq
	return [list $title $view_count $likes $dislikes $bywho $date $duration $short_url $link_counter]
}

###
proc search:youtube {nick host hand chan arg} {
if {![channel get $chan ytsearch]} {
	return
}
	set flood_protect [youtube:flood:prot $chan $host]
if {$flood_protect == "1"} {
	return
}
	set text [lrange [split $arg] 0 end]
if {$text == ""} {
	return
}
	set text [join $text "+"]
	set get_id [ytitle:get_idsearch $text]
if {$get_id == "-1"} {
	youtube:tell $nick $chan 0 1
} else {
	set url "https://www.youtube.com/watch?v=$get_id"
	youtube:get:title $url $nick $chan 1
	}
}

###
proc check:youtube {nick host hand chan arg} {
	set arg [split $arg]
if {![channel get $chan ytitle]} {
	return
}
	set flood_protect [youtube:flood:prot $chan $host]
if {$flood_protect == "1"} {
	return
}
foreach word $arg {
	set youtube_link "$word"
if {[string match -nocase "*youtube.com/watch*" $youtube_link] || [string match -nocase "*youtu.be*" $youtube_link]} {
	youtube:get:title $youtube_link $nick $chan 0
		}
	}
}

###
proc youtube:get:title {link nick chan type} {
	set novideo 0
	set live 0
	set output [ytitle:data $link]
if {$output == "0"} {
	youtube:tell $nick $chan 0 1
	return
}
	set title [string map { "&amp;" "&"
			"&#39;" "'"
			"&quot;" "\""
} [lindex $output 0]]
	set title [concat $title]
if {$title == ""} { set novideo 1}
	set views [lindex $output 1]
if {$views == ""} { set views "N/A" }
	set likes [lindex $output 2]
	set dontlike [lindex $output 3]
	set bywho [concat [lindex $output 4]]
	set update [lindex $output 5]
	set duration [lindex $output 6]
	set total_links [lindex $output 8]
	set get_link [lindex $output 7]
	set duration [string map {"PT" ""} $duration]
	set minutes [lindex [split $duration "M"] 0]
	set seconds [concat [string map {"S" ""} [lindex [split $duration "M"] 1]]]
	set scan [clock scan $update -format {%Y-%m-%d}]
	set update [clock format $scan -format {%d/%m/%Y}]
	set like_bar [youtube:like_bar $likes $dontlike $chan]
if {$views == ""} { set views "N/A" }
	youtube:tell $nick $chan $type [list $title $bywho $views $like_bar $dontlike $update $minutes $seconds $total_links $get_link]
}

###
proc youtube:tell {nick chan search arg} {
	global black ytitle
	set inc 0
foreach s $arg {
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
if {$search == "1"} {
if {$setcolor == "1"} {
	set type 5
	} else { set type 4 }
if {[info exists black(ytitle.$getlang.$type)]} {
	set reply [string map [array get replace] $black(ytitle.$getlang.$type)]
	putserv "PRIVMSG $chan :$reply"
	}
} else {
if {$setcolor == "1"} {
	set type 2
} else { set type 1 }
if {[info exists black(ytitle.$getlang.$type)]} {
	set reply [string map [array get replace] $black(ytitle.$getlang.$type)]
	putserv "PRIVMSG $chan :$reply"
		}
	}
}

###
proc youtube:getlang {chan} {
	global black ytitle
	set getlang [string tolower [channel get $chan ytlang]]
if {$getlang == ""} {
	set lang $ytitle(default_lang)
		} else {
	set lang $getlang
		}
	return [string tolower $lang]
}

###
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

###
proc check:youtube:me {nick host hand chan keyword arg} {
	check:youtube $nick $host $hand $chan $arg
	return
}

###
proc youtube:flood:prot {chan host} {
	global ytitle
	set number [scan $ytitle(flood_prot) %\[^:\]]
	set timer [scan $ytitle(flood_prot) %*\[^:\]:%s]
if {[info exists ytitle(flood:$host:$chan:act)]} {
	return 1
}
foreach tmr [utimers] {
if {[string match "*youtube:remove:flood $host $chan*" [join [lindex $tmr 1]]]} {
	killutimer [lindex $tmr 2]
	}
}
if {![info exists ytitle(flood:$host:$chan)]} {
	set ytitle(flood:$host:$chan) 0
}
	incr ytitle(flood:$host:$chan)
	utimer $timer [list youtube:remove:flood $host $chan]
if {$ytitle(flood:$host:$chan) > $number} {
	set ytitle(flood:$host:$chan:act) 1
	utimer [expr $ytitle(ignore_prot) * 60] [list youtube:expire:flood $host $chan]
	return 1
	} else {
	return 0
	}
}


###
proc youtube:remove:flood {host chan} {
	global ytitle
if {[info exists ytitle(flood:$host:$chan)]} {
	unset ytitle(flood:$host:$chan)
	}
}

###
proc youtube:expire:flood {host chan} {
	global ytitle
if {[info exists ytitle(flood:$host:$chan:act)]} {
	unset ytitle(flood:$host:$chan:act)
	}
}

set ytitle(projectName) "Youtube Title"
set ytitle(author) "BLaCkShaDoW"
set ytitle(website) "wWw.TCLScriptS.NeT"
set ytitle(version) "v2.2"

###
proc youtube:percentage {total number} {
  if {$total > 0} {
   return [expr $number / [expr $total / 100]];
  } else {
    return 0;
  }
}

###
proc youtube:like_bar {like dislike chan} {
	global ytitle
	set setcolor [youtube:getcolor $chan]
if {$like == "" && $dislike == ""} {
if {$setcolor == "1"} {
	return "\00304N/A\003"
} else {
	return "\002N/A\002"
	}
}
if {![regexp {%} $like]} {
		set sum [expr $like + $dislike]
		set like [youtube:percentage $sum $like]
		set dislike [youtube:percentage $sum $dislike]
} else {
	set like [string map {"%" ""} $like]
	set dislike [string map {"%" ""} $dislike]
}

if {$like > $dislike} {
	set dif [expr $like - $dislike]
} else {
	set dif [expr $dislike - $like]
}
	set like_star "&#9733"
	set dislike_star "&#9734"
	set dif [expr {double(round(1000*$dif))/1000.0}]
if {[expr {round($dif / 10)}] > 10} {
	set red 10
	set green [expr {10 - $red}]
} else {
	set red [expr {round($dif / 10)}]
	set green [expr {10 - $red}]
}
if {$like > $dislike} {
if {$red > $green} {
	set temp $green
	set green $red
	set red $temp
	}
}
if {$setcolor == "1"} {
	set output \00303[string repeat [youtube:format_star $like_star] $green]\003\00304[string repeat [youtube:format_star $dislike_star] $red]\003
} else {
	set output [string repeat [youtube:format_star $like_star] $green][string repeat [youtube:format_star $dislike_star] $red]
}
	return $output
}

###
proc youtube:format_star {string} {
    set map {}
    foreach {entity number} [regexp -all -inline {&#(\d+)} $string] {
        lappend map $entity [format \\u%04x [scan $number %d]]
    }
    set string [string map [subst -nocomm -novar $map] $string]
	return $string
 }

#Languages

# Romanian

set black(ytitle.ro.1) "\002\[YouTube\]\002 Titlu:\002 %msg.1%\002 | Publicat de:\002 %msg.2%\002 | Durata:\002 %msg.7%m%msg.8%s\002 | Data:\002 %msg.6%\002 | Vizionari:\002 %msg.3%\002 | Apreciere: %msg.4% - \[\002%msg.9%\002\] -"
set black(ytitle.ro.2) "\[\002You\0030,4Tube\003\002\003\] \00310Titlu:\0034 %msg.1% \003| \00310Publicat de:\0034 %msg.2% \003| \00310Durata:\0034 %msg.7%m%msg.8%s\003 | \00310Data:\0034 %msg.6% \003| \00310Vizionari:\0034 %msg.3% \003| \00310Apreciere:\003 %msg.4% - \[\00304%msg.9%\003\] -"
set black(ytitle.ro.3) "\002\[YouTube\]\002 Acest videoclip nu exista."
set black(ytitle.ro.4) "\002\[YouTube\]\002 Titlu:\002 %msg.1%\002 | Publicat de:\002 %msg.2%\002 | Durata:\002 %msg.7%m%msg.8%s\002 | Data:\002 %msg.6%\002 | Vizionari:\002 %msg.3%\002 | Apreciere: %msg.4% | Legatura: \002%msg.10%\002 - \[\002%msg.9%\002\] -"
set black(ytitle.ro.5) "\[\002You\0030,4Tube\003\002\003\] \00310Titlu:\0034 %msg.1% \003| \00310Publicat de:\0034 %msg.2% \003| \00310Durata:\0034 %msg.7%m%msg.8%s\003 | \00310Data:\0034 %msg.6% \003| \00310Vizionari:\0034 %msg.3% \003| \00310Apreciere:\003 %msg.4% | \00310Legatura: \0034%msg.10%\003 - \[\00304%msg.9%\003\] -"
# English

set black(ytitle.en.1) "\002\[YouTube\]\002 Title:\002 %msg.1%\002 | Uploaded by:\002 %msg.2%\002 | Length:\002 %msg.7%m%msg.8%s\002 | Date:\002 %msg.6%\002 | Views:\002 %msg.3%\002 | Like: %msg.4% - \[\002%msg.9%\002\] -"
set black(ytitle.en.2) "\[\002You\0030,4Tube\003\002\003\] \00310Title:\0034 %msg.1% \003| \00310Uploaded by:\0034 %msg.2% \003| \00310Length:\0034 %msg.7%m%msg.8%s\003 | \00310Date:\0034 %msg.6% \003| \00310Views:\0034 %msg.3% \003| \00310Like:\003 %msg.4% - \[\00304%msg.9%\003\] -"
set black(ytitle.en.3) "\002\[YouTube\]\002 This video does not exist."
set black(ytitle.en.4) "\002\[YouTube\]\002 Title:\002 %msg.1%\002 | Uploaded by:\002 %msg.2%\002 | Length:\002 %msg.7%m%msg.8%s\002 | Date:\002 %msg.6%\002 | Views:\002 %msg.3%\002 | Like: %msg.4% | Link:\002 %msg.10%\002 - \[\002%msg.9%\002\] -"
set black(ytitle.en.5) "\[\002You\0030,4Tube\003\002\003\] \00310Title:\0034 %msg.1% \003| \00310Uploaded by:\0034 %msg.2% \003| \00310Length:\0034 %msg.7%m%msg.8%s\003 | \00310Date:\0034 %msg.6% \003| \00310Views:\0034 %msg.3% \003| \00310Like:\003 %msg.4% | \00310Link: \0034%msg.10%\003 - \[\00304%msg.9%\003\] -"
# French

set black(ytitle.fr.1) "\002\[YouTube\]\002 Titre:\002 %msg.1%\002 | Telecharge par:\002 %msg.2%\002 | Duree:\002 %msg.7%m%msg.8%s\002 La date:\002 %msg.6%\002 | Vues:\002 %msg.3%\002 | J'aime: %msg.4% - \[\002%msg.9%\002\] -"
set black(ytitle.fr.2) "\[\002You\0030,4Tube\003\002\003\] \00310Titre:\0034 %msg.1% \003| \00310Telecharge par:\0034 %msg.2% \003| \00310Duree:\0034 %msg.7%m%msg.8%s\003 | \00310La date:\0034 %msg.6% \003| \00310Vues:\0034 %msg.3% \003| \00310J'aime:\003 %msg.4% - \[\00304%msg.9%\003\] -"
set black(ytitle.fr.3) "\002\[YouTube\]\002 Cette video n'existe pas."
set black(ytitle.fr.4) "\002\[YouTube\]\002 Titre:\002 %msg.1%\002 | Telecharge par:\002 %msg.2%\002 | Duree:\002 %msg.7%m%msg.8%s\002 La date:\002 %msg.6%\002 | Vues:\002 %msg.3%\002 | J'aime: %msg.4% | Lien:\002 %msg.10%\002 - \[\002%msg.9%\002\] -"
set black(ytitle.fr.5) "\[\002You\0030,4Tube\003\002\003\] \00310Titre:\0034 %msg.1% \003| \00310Telecharge par:\0034 %msg.2% \003| \00310Duree:\0034 %msg.7%m%msg.8%s\003 | \00310La date:\0034 %msg.6% \003| \00310Vues:\0034 %msg.3% \003| \00310J'aime:\003 %msg.4% | \00310Lien: \0034%msg.10%\003 - \[\00304%msg.9%\003\] -"
# Spanish

set black(ytitle.es.1) "\002\[YouTube\]\002 Titulo:\002 %msg.1%\002 | Cargado por:\002 %msg.2%\002 | Duracion:\002 %msg.7%m%msg.8%s\002 | Fecha:\002 %msg.6%\002 | Visualizaciones:\002 %msg.3%\002 | Gustos: %msg.4% - \[\002%msg.9%\002\] -"
set black(ytitle.es.2) "\[\002You\0030,4Tube\003\002\003\] \00310Titulo:\0034 %msg.1% \003| \00310Cargado por:\0034 %msg.2% \003| \00310Duracion:\0034 %msg.7%m%msg.8%s\003 | \00310Fecha:\0034 %msg.6% \003| \00310Visualizaciones:\0034 %msg.3% \003| \00310Gustos:\003 %msg.4% - \[\00304%msg.9%\003\] -"
set black(ytitle.es.3) "\002\[YouTube\]\002 Este video no existe."
set black(ytitle.es.4) "\002\[YouTube\]\002 Titulo:\002 %msg.1%\002 | Cargado por:\002 %msg.2%\002 | Duracion:\002 %msg.7%m%msg.8%s\002 | Fecha:\002 %msg.6%\002 | Visualizaciones:\002 %msg.3%\002 | Gustos: %msg.4% | Enlazar:\002 %msg.10%\002 - \[\002%msg.9%\002\] -"
set black(ytitle.es.5) "\[\002You\0030,4Tube\003\002\003\] \00310Titulo:\0034 %msg.1% \003| \00310Cargado por:\0034 %msg.2% \003| \00310Duracion:\0034 %msg.7%m%msg.8%s\003 | \00310Fecha:\0034 %msg.6% \003| \00310Visualizaciones:\0034 %msg.3% \003| \00310Gustos:\003 %msg.4% | \00310Enlazar: \0034%msg.10%\003 - \[\00304%msg.9%\003\] -"
# Italian

set black(ytitle.it.1) "\002\[YouTube\]\002 Titolo:\002 %msg.1%\002 | Caricato da:\002 %msg.2%\002 | Durata:\002 %msg.7%m%msg.8%s\002 | Data:\002 %msg.6%\002 | Visualizzazioni:\002 %msg.3%\002 | Piace: %msg.4% - \[\002%msg.9%\002\] -"
set black(ytitle.it.2) "\[\002You\0030,4Tube\003\002\003\] \00310Titolo:\0034 %msg.1% \003| \00310Caricato da:\0034 %msg.2% \003| \00310Durata:\0034 %msg.7%m%msg.8%s\003 | \00310Data:\0034 %msg.6% \003| \00310Visualizzazioni:\0034 %msg.3% \003| \00310Piace:\003 %msg.4% - \[\00304%msg.9%\003\] -"
set black(ytitle.it.3) "\002\[YouTube\]\002 Questo video non esiste."
set black(ytitle.it.4) "\002\[YouTube\]\002 Titolo:\002 %msg.1%\002 | Caricato da:\002 %msg.2%\002 | Durata:\002 %msg.7%m%msg.8%s\002 | Data:\002 %msg.6%\002 | Visualizzazioni:\002 %msg.3%\002 | Piace: %msg.4% | Collegamento:\002 %msg.10%\002 - \[\002%msg.9%\002\] -"
set black(ytitle.it.5) "\[\002You\0030,4Tube\003\002\003\] \00310Titolo:\0034 %msg.1% \003| \00310Caricato da:\0034 %msg.2% \003| \00310Durata:\0034 %msg.7%m%msg.8%s\003 | \00310Data:\0034 %msg.6% \003| \00310Visualizzazioni:\0034 %msg.3% \003| \00310Piace:\003 %msg.4% | \00310Collegamento: \0034%msg.10%\003 - \[\00304%msg.9%\003\] -"

# german

set black(ytitle.de.1) "\002\[YouTube\]\002 Titel:\002 %msg.1%\002 | hochgeladen von:\002 %msg.2%\002 | Laenge:\002 %msg.7%m%msg.8%s\002 | Datum:\002 %msg.6%\002 | Aufrufe:\002 %msg.3%\002 | Like: %msg.4% - \[\002%msg.9%\002\] -"
set black(ytitle.de.2) "\[\002You\0030,4Tube\003\002\003\] \00310Title:\0034 %msg.1% \003| \00310Uploaded by:\0034 %msg.2% \003| \00310Length:\0034 %msg.7%m%msg.8%s\003 | \00310Datum:\0034 %msg.6% \003| \00310Aufrufe:\0034 %msg.3% \003| \00310Like:\003 %msg.4% - \[\00304%msg.9%\003\] -"
set black(ytitle.de.3) "\002\[YouTube\]\002 Das Video existiert nicht."
set black(ytitle.de.4) "\002\[YouTube\]\002 Titel:\002 %msg.1%\002 | hochgeladen von:\002 %msg.2%\002 | Laenge:\002 %msg.7%m%msg.8%s\002 | Datum:\002 %msg.6%\002 | Aufrufe:\002 %msg.3%\002 | Like: %msg.4% | Link:\002 %msg.10%\002 - \[\002%msg.9%\002\] -"
set black(ytitle.de.5) "\[\002You\0030,4Tube\003\002\003\] \00310Titel:\0034 %msg.1% \003| \00310hochgeladen von:\0034 %msg.2% \003| \00310Laenge:\0034 %msg.7%m%msg.8%s\003 | \00310Datum:\0034 %msg.6% \003| \00310Aufrufe:\0034 %msg.3% \003| \00310Like:\003 %msg.4% | \00310Link: \0034%msg.10%\003 - \[\00304%msg.9%\003\] -"

putlog "\002$ytitle(projectName) $ytitle(version)\002 coded by $ytitle(author) ($ytitle(website)): Loaded."

##############
##########################################################
##   END                                                 #
##########################################################
