
#!/bin/bash

interface=$1
counter=$2
received_bytes=""
transmitted_bytes=""

get_bytes()
{
        line=$(cat /proc/net/dev | grep $interface | cut -d ':' -f 2 | awk '{print "received_bytes="$1, "transmitted_bytes="$9}')
        eval $line
}

count_speed_u()
{
	speed=$1
	if [[ $speed -lt 1000 ]]; then
		echo -n "$speed B/s";
	elif [[ $speed -lt 1000000 ]]; then
		tmp1=$(echo "scale=2; $speed / 1000" | bc -l)
		echo -n "$tmp1 KB/s";
	else
		tmp2=$(echo "scale=2; $speed / 1000000" | bc -l)
		echo -n "$tmp2 MB/s";
	fi
}

count_time_d()
{
	time_v=$1
	time_d=$(($time_v/86400))
	echo -n "$time_d";
}

count_time_h()
{
	time_v=$(($1 - $(($2*86400))))
	time_h=$(($time_v/3600))
	echo -n "$time_h";
}

count_time_m()
{
	time_v=$(($1 - $(($2*86400)) - $(($3*3600))))
        time_m=$(($time_v/60))
        echo -n "$time_m";

}

count_time_s()
{
	time_v=$(($1 - $(($2*86400)) - $(($3*3600)) - $(($4*60))))
	echo -n "$time_v";

}

get_bytes
old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes

sleep 1
x=1;
total_speed_r="";
total_speed_t="";
battery=""

search_level_battery()
{
	battery=$(cat /sys/class/power_supply/BAT0/uevent | grep "POWER_SUPPLY_CAPACITY=" | cut -d '=' -f 2)
}

search_level_battery

loadavg_1m=$(cat /proc/loadavg | cut -d ' ' -f 1)
loadavg_5m=$(cat /proc/loadavg | cut -d ' ' -f 2)
loadavg_15m=$(cat /proc/loadavg | cut -d ' ' -f 3)

tablica_r[0]=""
tablica_t[0]=""
tablica_r_sort[0]=""
tablica_t_sort[0]=""

draw_chart_r()
{
	i=$1
	k=$2
	j=0;
	while [ $i -gt 0 ]; do
		echo -ne "${tablica_r_s_u[$j]}"
		p=$k;
		l=0;
		tput cub 20
		tput cuf 12
		while [ $p -gt 0 ]; do
			if [[ "${tablica_r[$l]}" -ge "${tablica_r_sort[$j]}" ]]; then
				if [[ $p -eq 1 ]]; then
					echo -e "\033[1;41;97m \033[32;41m\033[0m"
				else
					echo -ne "\033[1;41;97m \033[32;41m\033[0m "
				fi
			else
				if [[ $p -eq 1 ]]; then
                                        echo " "
                                else
                                        echo -n "  "
                                fi
			fi
			p=$((p - 1))
                	l=$((l + 1))
		done
		i=$((i - 1))
        	j=$((j + 1))
	done

	echo ""

        i=$3
        k=$4
        j=0;
        while [ $i -gt 0 ]; do
                echo -ne "${tablica_t_s_u[$j]}"
                p=$k;
                l=0;
                tput cub 20
                tput cuf 12
                while [ $p -gt 0 ]; do
                        if [[ "${tablica_t[$l]}" -ge "${tablica_t_sort[$j]}" ]]; then
                                if [[ $p -eq 1 ]]; then
					echo -e "\033[1;41;97m \033[32;41m\033[0m"
                                else
                                        echo -ne "\033[1;41;97m \033[32;41m\033[0m "
                                fi
                        else
                                if [[ $p -eq 1 ]]; then
                                        echo  " "
                                else
                                        echo -n  "  "
                                fi
                        fi
                        p=$((p - 1))
                        l=$((l + 1))
                done
                i=$((i - 1))
                j=$((j + 1))
        done
	unset tablica_r_s_u
	unset tablica_t_s_u
}

limit_columns()
{
	value_r=$1
	value_t=$2
	i=0;
	j=1;
	s=${#tablica_r[@]}
	s=$((s - 1))
	while [[ $s -gt 0 ]]; do
		tablica_r[$i]="${tablica_r[$j]}"
		tablica_t[$i]="${tablica_t[$j]}"
		s=$((s - 1))
		i=$((i + 1))
		j=$((j + 1))
	done
	tablica_r[$i]="$value_r"
        tablica_t[$i]="$value_t"
}

limit_values_r()
{
	new_value=$1
	size_r_s=${#tablica_r_sort[@]}
	size_r=${#tablica_r[@]}
	i=0;
	while [[ $i -lt $size_r_s ]]; do
		j=0;
		flaga=0;
		while [[ $j -lt $size_r ]]; do
			if [[ "${tablica_r_sort[$i]}" -eq "${tablica_r[$j]}" ]]; then
				flaga=$((flaga + 1))
			fi
			j=$((j + 1))
		done
		if [[ $flaga -eq 0 ]]; then
			s=$size_r_s
			k=$(($s - 1))
			while [[ $i -lt $k ]]; do
				j=$((i + 1))
				tablica_r_sort[$i]="${tablica_r_sort[$j]}"
				i=$((i + 1))
			done
			tablica_r_sort[$k]="$new_value"
			break
		fi
		i=$((i + 1))
	done
	sorting_r
}

limit_values_t()
{
        new_value=$1
        size_t_s=${#tablica_t_sort[@]}
        size_t=${#tablica_t[@]}
        i=0;
        while [[ $i -lt $size_t_s ]]; do
                j=0;
                flaga=0;
                while [[ $j -lt $size_t ]]; do
                        if [[ "${tablica_t_sort[$i]}" -eq "${tablica_t[$j]}" ]]; then
                                flaga=$((flaga + 1))
                        fi
                        j=$((j + 1))
                done
                if [[ $flaga -eq 0 ]]; then
                        s=$size_t_s
                        k=$(($s - 1))
                        while [[ $i -lt $k ]]; do
                                j=$((i + 1))
                                tablica_t_sort[$i]="${tablica_t_sort[$j]}"
                                i=$((i + 1))
                        done
                        tablica_t_sort[$k]="$new_value"
                        break
                fi
                i=$((i + 1))
        done
        sorting_t
}

sorting_r()
{
	i=0;
	size=${#tablica_r_sort[@]}
	while [[ $i -lt $size ]]; do
		j=1;
		s=$(($size - $i))
        	while [[ $j -lt $s ]]; do
			k=$(($j - 1))
                	if [[ "${tablica_r_sort[$k]}" -lt "${tablica_r_sort[$j]}" ]]; then
                        	tmp="${tablica_r_sort[$k]}"
                        	tablica_r_sort[$k]="${tablica_r_sort[$j]}"
                        	tablica_r_sort[$j]=$tmp
                	fi
			j=$((j + 1))
        	done
		i=$((i + 1))
	done
}

sorting_t()
{
        i=0;
        size=${#tablica_t_sort[@]}
        while [[ $i -lt $size ]]; do
                j=1;
                s=$(($size - $i))
                while [[ $j -lt $s ]]; do
                        k=$(($j - 1))
                        if [[ "${tablica_t_sort[$k]}" -lt "${tablica_t_sort[$j]}" ]]; then
                                tmp="${tablica_t_sort[$k]}"
                                tablica_t_sort[$k]="${tablica_t_sort[$j]}"
                                tablica_t_sort[$j]=$tmp
                        fi
                        j=$((j + 1))
                done
                i=$((i + 1))
        done
}

while [ true ]; do
	tput civis
	tput cup 1 0
	get_bytes
	difference_r=$(($received_bytes - $old_received_bytes))
	total_speed_r=$((total_speed_r + difference_r))
        difference_t=$(($transmitted_bytes - $old_transmitted_bytes))
        total_speed_t=$((total_speed_t + difference_t))
	speed_r=$(count_speed_u $difference_r)
	speed_t=$(count_speed_u $difference_t)
	wsk=$((x - 1))

	if [[ $wsk -ge $counter ]]; then
		limit_columns $difference_r $difference_t
	else
		tablica_r[$wsk]="$difference_r"
	        tablica_t[$wsk]="$difference_t"

	fi

	size_r_s=${#tablica_r_sort[@]}
        size_t_s=${#tablica_t_sort[@]}

	if [[ $wsk -eq 0 ]]; then
        	tablica_r_sort[0]="$difference_r"
        	tablica_t_sort[0]="$difference_t"
        else
		i=0;
		flag=0;
		while [[ $i -lt $size_r_s ]]; do
			if [[ "${tablica_r_sort[$i]}" -eq $difference_r ]]; then 
				flag=$((flag + 1))
			fi
			i=$((i + 1))
		done
		if [[ $flag -eq 0 ]]; then
			if [[ $size_r_s -ge $counter ]]; then
				limit_values_r $difference_r
			else
				tablica_r_sort[$size_r_s]="$difference_r"
				sorting_r
			fi
		fi

		j=0;
                flaga=0;
                while [[ $j -lt $size_t_s ]]; do
                        if [[ "${tablica_t_sort[$j]}" -eq $difference_t ]]; then 
                                flaga=$((flaga + 1))
                        fi
                        j=$((j + 1))
                done
                if [[ $flaga -eq 0 ]]; then
			if [[ $size_t_s -ge $counter ]]; then
				limit_values_t $difference_t
			else
                        	tablica_t_sort[$size_t_s]="$difference_t"
				sorting_t
			fi
                fi
	fi

	average_speed_r=$((total_speed_r / x))
	average_speed_t=$((total_speed_t / x))
	average_speed_r_u=$(count_speed_u $average_speed_r)
	average_speed_t_u=$(count_speed_u $average_speed_t)
	old_received_bytes=$received_bytes
	old_transmitted_bytes=$transmitted_bytes
	x=$[x + 1]

	time_value=$(cat /proc/uptime | cut -d '.' -f 1)
	time_u_d=$(count_time_d $time_value)
	time_u_h=$(count_time_h $time_value $time_u_d)
	time_u_m=$(count_time_m $time_value $time_u_d $time_u_h)
	time_u_s=$(count_time_s $time_value $time_u_d $time_u_h $time_u_m)

        declare -a tablica_r_s_u
        for a in ${tablica_r_sort[@]}
        do
                tablica_r_s_u+=("$(count_speed_u $a)")
        done

        declare -a tablica_t_s_u
        for a in ${tablica_t_sort[@]}
        do
                tablica_t_s_u+=("$(count_speed_u $a)")
        done

	sleep 1;
	clear
	echo "Present speed $interface DOWN: $speed_r   UP: $speed_t"
        echo "Average speed $interface DOWN: $average_speed_r_u   UP: $average_speed_t_u"
	echo ""
	echo "Uptime: $time_u_d dzien $time_u_h godzina $time_u_m minuta $time_u_s sekunda"

	echo "Battery: $battery%"

	echo "Load_Avg:"
	echo -e "\tIn time 1 min:"
	echo -e "\t\t$loadavg_1m"
	echo -e "\tIn time 5 min:"
	echo -e "\t\t$loadavg_5m"
	echo -e "\tIn time 15 min:"
	echo -e "\t\t$loadavg_15m"
	echo -e ""
	draw_chart_r ${#tablica_r_sort[@]} ${#tablica_r[@]} ${#tablica_t_sort[@]} ${#tablica_r[@]}

	search_level_battery
        loadavg_1m=$(cat /proc/loadavg | cut -d ' ' -f 1)
        loadavg_5m=$(cat /proc/loadavg | cut -d ' ' -f 2)
        loadavg_15m=$(cat /proc/loadavg | cut -d ' ' -f 3)
done
