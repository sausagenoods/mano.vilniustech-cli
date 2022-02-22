#!/bin/sh
# CLI client for mano.vilniustech.lt
# Copyright (C) 2022 İrem Kuyucu <siren@kernal.eu>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

username='student_id'
password='s3cure'
rememberme='true'
cachedir=~/.cache/mano.vilniustech
tokenfile=$cachedir/token

first_semester_start='2021-09-01'
first_semester_end='2021-12-15'
second_semester_start='2022-02-07'
second_semester_end='2022-05-22'

baseurl='https://ws.vgtu.lt/api/ManoVGTUapp/1.0'

check_token() {
	if [ ! -d $cachedir ]
	then
		mkdir -p $cachedir
	fi
	if [ ! -f $tokenfile ]
	then
		get_token
		return
	fi
	if [ `wc -c < $tokenfile` -ne 1087 ]
	then
		get_token
		return
	fi

	# Check if the token we already have is still valid
	# Else aqcuire a new token
	if [ `date +%s` -ge `date -d $(head -n 1 "$tokenfile") +%s` ]
	then
		get_token
	else
		token=`tail -n 1 "$tokenfile"`
	fi
}

# Get access token and its validity
get_token() {
	login=`curl -s -H 'Content-Type: application/json' \
		-d "{\"username\":\"$username\",\"password\":\"$password\",\"remember_me\":\"$rememberme\"}" \
		http://ws.vgtu.lt/api/auth/login`
	if ! [ "$login" ]
	then
		echo 'Failed to log in and aqcuire access token.'
		exit 1
	fi
	if echo "$login" | grep -q 'Unauthorized'
	then
		echo 'Account blacklisted, rate-limited or wrong credentials supplied.'
		exit 1
	fi
	token=`echo "$login" | jq -r .access_token`
	expires=`echo "$login" | jq -r .expires_at | cut -d' ' -f1`
	echo "$expires" > $tokenfile
	echo "$token" >> $tokenfile
}

get_json() {
	json=`curl -s -H 'Content-Type: application/json' \
		-H "Authorization: Bearer $token" "$baseurl$1" | jq '.[]'`
	if echo "$json" | grep -q 'invalid'
	then
		# They take down the API at nights for some reason
		echo 'The endpoint failed to respond.'
		exit 2
	fi
}

print_lectures() {
	cat $lectures_json | jq -r \
		"select(.SEMESTRAS == \"$1\") | select(.SAV_INTERVAL != \"$2\") | .DIENA_ANGL+\";\"+.LAIKAS+\";\"+.DAL_PAVAD_ANGL+\";\"+.AUDITORIJA_ANGL" \
		| column -s';' -t | cut -d':' -f1,2,3 | sed 's/Auditorium //g'
}

get_current_interval() {
	today=`date -d $(date +%Y-%m-%d) '+%s'`
	if [ `date +%s -d "$first_semester_start"` -le `date +%s` ] && [ `date +%s -d "$first_semester_end"` -ge `date +%s` ]
	then
		semester=1
	elif [ `date +%s -d "$second_semester_start"` -le `date +%s` ] && [ `date +%s -d "$second_semester_end"` -ge `date +%s` ]
	then
		semester=2
	else
		echo 'There are no lectures.'
		exit 0
	fi
	days=$((( ($today-$(date +%s -d $second_semester_start)) / 86400 + 1) % 14 ))
	if [ $days -le 7 ]
	then
		not_week=2
	else
		not_week=1
	fi
}

get_lectures() {
	lectures_json=$cachedir/lectures.json
	if [ ! -f $lectures_json ]
	then
		get_json '/student/timetable'
		echo "$json" > $lectures_json
	fi
	if [ "$1" = "today" ]
	then
		get_current_interval
		print_lectures $semester $not_week | grep `date +%A` | tr -s ' ' | cut -d ' ' -f2-
		exit 0
	fi
	case "$2" in
		all)
			echo 'Week 1'
			print_lectures $1 2
			echo '\nWeek 2'
			print_lectures $1 1
			;;
		1)
			print_lectures $1 2
			;;
		2)
			print_lectures $1 1
			;;
		*)
			get_current_interval
			print_lectures $semester $not_week
			;;
	esac
}

get_exam_schedule() {
	get_json '/student/examschedule'
	echo $json | jq -r \
		'.MOD_ANGL_PAV+";"+.DATA+";"+.LAIKAS+";"+.AUDITORIJA' \
		| column -s';' -t
}

get_exam_results() {
	get_json '/student/examresults'
	echo $json | jq -r \
		'.MOD_ANGL_PAV+";"+.IVERTINIMAS' \
		| column -s';' -t
}

get_audience() {
	get_json '/common/audience'
	echo "$json" | jq -r \
		'.PAST_PAV+";"+.PAST_ADRESAS+";"+.PAST_PAVAD_ANGL+";"+.AUKSTAS' \
		| column -s';' -t
}

check_token

case "$1" in
	lecture-schedule)
		get_lectures "$2" "$3" > $cachedir/lecture_schedule
		;;
	exam-schedule)
		get_exam_schedule > $cachedir/exam_schedule
		;;
	exam-results)
		get_exam_results > $cachedir/exam_results
		;;
	audience)
		get_audience > $cachedir/audience
		;;
	get-token)
		get_token
		;;
	*)
	echo 'Unknown option. Available:'
	echo 'lecture-schedule [1, 2, today] [all, 1, 2]'
	echo 'exam-schedule'
	echo 'exam-results'
	echo 'audience'
	echo 'get-token'
esac
