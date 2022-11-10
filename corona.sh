#!/bin/sh

#Elena Marochkina
#xmaroc00

export POSIXLY_CORRECT=yes
export LC_ALL=C
export LC_NUMERIC=en_US.UTF-8

usage(){
   echo "Command: corona [-h] [FILTERS] [COMMAND] [LOG [LOG2 [...]]"
    echo " "
    echo "Corona — analyzátor záznamů osob s prokázanou nákazou koronavirem způsobujícím onemocnění COVID-19"
    echo " "
    echo "Command:"
    echo "  infected — spočítá počet nakažených."
    echo "  merge — sloučí několik souborů se záznamy do jednoho, zachovávající původní pořadí (hlavička bude ve výstupu jen jednou)."
    echo "  gender — vypíše počet nakažených pro jednotlivá pohlaví."
    echo "  age — vypíše statistiku počtu nakažených osob dle věku (bližší popis je níže)."
    echo "  daily — vypíše statistiku nakažených osob pro jednotlivé dny."
    echo "  monthly — vypíše statistiku nakažených osob pro jednotlivé měsíce."
    echo "  yearly — vypíše statistiku nakažených osob pro jednotlivé roky."
    echo "  countries — vypíše statistiku nakažených osob pro jednotlivé země nákazy (bez ČR, tj. kódu CZ)."
    echo "  districts — vypíše statistiku nakažených osob pro jednotlivé okresy."
    echo "  regions — vypíše statistiku nakažených osob pro jednotlivé kraje."
    echo " "
    echo "FILTERS:"
    echo "  -a DATETIME — after: jsou uvažovány pouze záznamy PO tomto datu (včetně tohoto data). DATETIME je formátu YYYY-MM-DD."
    echo "  -b DATETIME — before: jsou uvažovány pouze záznamy PŘED tímto datem (včetně tohoto data)."
    echo "  -g GENDER — jsou uvažovány pouze záznamy nakažených osob daného pohlaví. GENDER může být M (muži) nebo Z (ženy)."
    echo "  -s [WIDTH] u příkazů gender, age, daily, monthly, yearly, countries, districts a regions vypisuje data ne číselně, ale graficky v podobě histogramů. Nepovinný parametr WIDTH nastavuje šířku histogramů, tedy délku nejdelšího řádku, na WIDTH. Tedy, WIDTH musí být kladné celé číslo. Pokud není parametr WIDTH uveden, řídí se šířky řádků požadavky uvedenými níže."
    echo " "
    echo "NÁPOVĚDA:"
    echo "  -h — vypíše nápovědu s krátkým popisem každého příkazu a přepínače."
}

GZ_FILES=""
BZ_FILES=""
LOG_FILES=""
COMMAND="none"
INPUT=

DATE_AFTER=
DATE_BEFORE=
GENDER=""
WIDTH=""
STDERR_AGE=""
STDERR_DATE=""

graf_flag=0

#delete inappropriate lines
clean(){
    INPUT=$(echo "$INPUT" | sed "s/ \{1,5\}//g" | awk -F ',' '!/^$/ {if ($1!~"id") print $0}') #remove spaces, empty lines, tab lines
}

#age validation
valid_age(){
    STDERR_AGE=$(echo "$INPUT" | awk -F ',' '{if ($3 != "" && $3 !~ /^[0-9]+$/) print $0}')
    INPUT=$(echo "$INPUT" | awk -F ',' '{if ($3 == "" || $3 ~ /^[0-9]+$/) print $0}')  
}

#date validation
valid_date(){
    STDERR_DATE=$(echo "$INPUT" | awk -F ',' '{if ($2 != "" && $2 !~ /^[0-9]{4}-(02-(0[1-9]|[12][0-9])|(0[469]|11)-(0[1-9]|[12][0-9]|30)|(0[13578]|1[02])-(0[1-9]|[12][0-9]|3[01]))+$/) print $0}')
    INPUT=$(echo "$INPUT" | awk -F ',' '{if ($2 == "" || $2 ~ /^[0-9]{4}-(02-(0[1-9]|[12][0-9])|(0[469]|11)-(0[1-9]|[12][0-9]|30)|(0[13578]|1[02])-(0[1-9]|[12][0-9]|3[01]))+$/) print $0}')  
}

#data validation overall
valid_data(){
    clean
    valid_age
    valid_date
}

invalid_data_printing (){
    if [[ $STDERR_DATE != "" ]]; then
    echo Invalid date:"$STDERR_DATE"
    fi
    if [[ $STDERR_AGE != "" ]]; then
    echo Invalid age:"$STDERR_AGE"
    fi
}

#manually check for -h option - or use getopt next time!
for arg in "$@"; do
    if [ "$arg" = '-h' ]; then
        usage
        exit 0
    fi
done

#TODO remake AFTER/BEFORE if selected multiple times
#parsing options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a)
            DATE_AFTER="$2"
            shift 2
            ;;
        -b)
            DATE_BEFORE="$2"
            shift 2
            ;;
        -g) 
            GENDER="$2"
            shift 2
            ;;
        -s)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                graf_flag=1
                WIDTH=0
                shift
            else
                graf_flag=1
                WIDTH="$2"
                shift 2
            fi;;
        -h) usage; exit 0;;
        *) 
            case "$1" in
                infected) COMMAND="infected";shift;;
                merge) COMMAND="merge";shift;;
                gender) COMMAND="gender";shift;;
                age) COMMAND="age"; shift;;
                daily) COMMAND="daily";shift;;
                monthly) COMMAND="monthly";shift;;
                yearly) COMMAND="yearly";shift;;
                countries) COMMAND="countries";shift;;
                districts) COMMAND="districts";shift;;
                regions) COMMAND="regions";shift;;
            esac
            
            if [[ "$1" =~ \.gz$ ]]; then
                GZ_FILES="$1 $GZ_FILES"
                INPUT="$INPUT $(gzip -d -c $GZ_FILES)"
                valid_data
            elif [[ "$1" =~ \.bz2$ ]]; then
                BZ_FILES="$1 $BZ_FILES"
                INPUT="$INPUT $(bzip2 -d -c $BZ_FILES)"
                valid_data
            elif [[ "$1" =~ \.csv$ ]]; then
                LOG_FILES="$1 $LOG_FILES"
                INPUT="$INPUT $(cat $LOG_FILES)"
                valid_data
            else
                INPUT=$(cat)
                 valid_data
            fi
            shift
            ;;
    esac
done

#set contents of files to variable input
# if [[ -n "$GZ_FILES" ]]; then
#     INPUT="$INPUT $(gzip -d -c $GZ_FILES)"
#     valid_data
# fi

# if ![[ -n "$BZ_FILES" ]]; then
#     INPUT="$INPUT $(bzip2 -d -c $BZ_FILES)"
#     valid_data
# fi

# if [[ -n "$LOG_FILES" ]]; then
#     INPUT="$INPUT $(cat $LOG_FILES)"
#     valid_data
# else
#     INPUT=$(cat)
#     valid_data
# fi

#apply options [after, before, gender] from getopts
if [ "$GENDER" != "" ]; then 
    INPUT=$(echo "$INPUT" | awk -F ',' -v filters="$GENDER" '$4 ~ (filters) {print $0}') 
fi

if [ "$DATE_AFTER" != "" ]; then 
    INPUT=$(echo "$INPUT" | awk -F ',' -v filter="$DATE_AFTER" '{if ($2 >= filter) print $0}') 
fi

if [ "$DATE_BEFORE" != "" ]; then 
    INPUT=$(echo "$INPUT" | awk -F ',' -v filter="$DATE_BEFORE" '{if ($2 <= filter) print $0}')
fi

#default action, when no command is called
if [ "$COMMAND" = 'none' ]; then
    echo -e "id,datum,vek,pohlavi,kraj_nuts_kod,okres_lau_kod,nakaza_v_zahranici,nakaza_zeme_csu_kod,reportovano_khs\n$INPUT"
    invalid_data_printing

#infected function 
elif [ "$COMMAND" = "infected" ]; then
    echo "$INPUT" | awk 'END {print NR}'
    invalid_data_printing

# merge function 
elif [ "$COMMAND"  = "merge" ]; then
    echo "id,datum,vek,pohlavi,kraj_nuts_kod,okres_lau_kod,nakaza_v_zahranici,nakaza_zeme_csu_kod,reportovano_khs"
    echo "$INPUT"
    invalid_data_printing

# gender function
elif [ "$COMMAND" = "gender" ]; then 
    if [[ $WIDTH == 0 ]]; then
		WIDTH=100000
	fi
    max=$(echo "$INPUT" | awk -F ',' '{if ($4 != "") print $4}' | sort | uniq -c | awk '{print $1}' | awk 'NR == 1{print$1}')
    echo "$INPUT" | awk -v width=$WIDTH -v graf_flag=$graf_flag -v max=$max -F ',' '{
        if ($4 == "M") m++
        else if ($4 == "Z") z++
        else n++
        } 
        END {
            if(!graf_flag) {
                if(m!=0) {
                    printf("M: %d\n", m)
                }
                if(z!=0){
                    printf("Z: %d\n", z)
                }
                if(n!=0){
                printf("None: %d\n", n)
            }
        }
            else { 
                if (width == 100000) {
                    new_width = 100000
                } else {
                    new_width = max/width
                }
                if(m!=0){
                    m_graf = int(m / new_width)
                            printf("M: ")
                            for (i = 0; i < m_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }
                if(z!=0){
                    z_graf = int(z / new_width)
                            printf("Z: ")
                            for (i = 0; i < z_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }
                if(n!=0) {
                    n_graf = int(n / new_width)
                            printf("None: ")
                            for (i = 0; i < n_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }
            }     
        }' 
        invalid_data_printing

# age function 
elif [ "$COMMAND" = "age" ]; then 
    if [[ $WIDTH == 0 ]]; then
		WIDTH=10000
	fi
    echo "$INPUT" |
    awk -v width=$WIDTH -v graf_flag=$graf_flag -F ',' '{
        if ($3 >= 0 && $3<= 5) a0_5++
        else if ($3 >= 6 && $3 <= 15) a6_15++
        else if ($3 >= 16 && $3 <= 25) a16_25++
        else if ($3 >= 26 && $3 <= 35) a26_35++
        else if ($3 >= 36 && $3 <= 45) a36_45++
        else if ($3 >= 46 && $3 <= 55) a46_55++
        else if ($3 >= 56 && $3 <= 65) a56_65++
        else if ($3 >= 66 && $3 <= 75) a66_75++
        else if ($3 >= 76 && $3 <= 85) a76_85++
        else if ($3 >= 86 && $3 <= 95) a86_95++
        else if ($3 >= 96 && $3 <= 105) a96_105++
        else if ($3 > 105) a105++
        else n++
        }
        END {
            if(!graf_flag) {
            printf("0-5   : %d\n6-15  : %d\n16-25 : %d\n26-35 : %d\n36-45 : %d\n46-55 : %d\n56-65 : %d\n66-75 : %d\n76-85 : %d\n86-95 : %d\n96-105: %d\n>105  : %d\n", 
        a0_5, a6_15, a16_25, a26_35, a36_45, a46_55, a56_65, a66_75, a76_85, a86_95, a96_105, a105)
        if(n!=0){
                printf("None  : %d\n", n)
            }
        }
            else { 
                max = a0_5
                if(max < a6_15){
                    max = a6_15
                }
                if(max < a16_25){
                    max = a16_25
                }
                if(max < a26_35){
                    max = a26_35
                }
                if(max < a36_45){
                    max = a36_45
                }
                if(max < a46_55){
                    max = a46_55
                }
                if(max < a56_65){
                    max = a56_65
                }
                if(max < a66_75){
                    max = a66_75
                }
                if(max < a76_85){
                    max = a76_85
                }
                if(max < a86_95){
                    max = a86_95
                }
                if(max < a96_105){
                    max = a96_105
                }
                if(max < a105){
                    max = a105
                }
                if(max < n){
                    max = n
                }
                if (width == 10000) {
                    new_width = 10000
                } else {
                    new_width = max/width
                }
                
                    a0_5_graf = int(a0_5 / new_width)
                            printf("0-5   : ")
                            for (i = 0; i < a0_5_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a6_15_graf = int(a6_15 / new_width)
                            printf("6-15  : ")
                            for (i = 0; i < a6_15_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a16_25_graf = int(a16_25 / new_width)
                            printf("16-25 : ")
                            for (i = 0; i < a16_25_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a26_35_graf = int(a26_35 / new_width)
                            printf("26-35 : ")
                            for (i = 0; i < a26_35_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a36_45_graf = int(a36_45 / new_width)
                            printf("36-45 : ")
                            for (i = 0; i < a36_45_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a46_55_graf = int(a46_55 / new_width)
                            printf("46-55 : ")
                            for (i = 0; i < a46_55_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a56_65_graf = int(a56_65 / new_width)
                            printf("56-65 : ")
                            for (i = 0; i < a56_65_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a66_75_graf = int(a66_75 / new_width)
                            printf("66-75 : ")
                            for (i = 0; i < a66_75_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a76_85_graf = int(a76_85 / new_width)
                            printf("76-85 : ")
                            for (i = 0; i < a76_85_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a86_95_graf = int(a86_95 / new_width)
                            printf("86-95 : ")
                            for (i = 0; i < a86_95_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a96_105_graf = int(a96_105 / new_width)
                            printf("96-105: ")
                            for (i = 0; i < a96_105_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                a105_graf = int(a105 / new_width)
                            printf(">105  : ")
                            for (i = 0; i < a105_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                if(n!=0) {
                    n_graf = int(n / new_width)
                            printf("None  : ")
                            for (i = 0; i < n_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }
            }             
        }' 
    invalid_data_printing

# daily
    elif [ "$COMMAND" = "daily" ]; then 
    if [[ $WIDTH == 0 ]]; then
		WIDTH=500
	fi
    inf=$(echo "$INPUT" | awk 'END {print NR}')
    day_known=$(echo "$INPUT" | awk -F ',' -v value=0 '{if ($2 != "") value++}END{printf("%d\n", value)}')
    missed_data=$((inf-day_known))
    max=$(echo "$INPUT" | awk -F ',' '{if ($2 != "") print $2}' | awk -F '-' '{print $3}'| sort | uniq -c | sort -r | awk 'NR == 1{print$1}')
    echo "$INPUT" | awk -F ',' '{if ($2 != "") print $2}' | sort -n| uniq -c |awk -v width=$WIDTH -v graf_flag=$graf_flag -v missed_data=$missed_data -v max=$max '{
        if(!graf_flag) {
            printf("%s: %d\n", $2, $1)
        }
        else {
            if (width == 500) {
                    new_width = 500
                } else {
                    new_width = max/width
                }
            day_graf = int($1 / new_width)
                            printf("%s: ", $2)
                            for (i = 0; i < day_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
        } 
        }
        END{
            if(!graf_flag && missed_data != 0) {
            printf("None: %d\n", (missed_data))
        }
        else {
            if (width == 500) {
                    new_width = 500
                } else {
                    new_width = max/width
                }
            if(missed_data>0) {
                    n_graf = int(missed_data / new_width)
                            printf("None: ")
                            for (i = 0; i < n_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }

        }  
    }'
    invalid_data_printing

# monthly
    elif [ "$COMMAND" = "monthly" ]; then 
    if [[ $WIDTH == 0 ]]; then
		WIDTH=10000
	fi
    inf=$(echo "$INPUT" | awk 'END {print NR}')
    month_known=$(echo "$INPUT" | awk -F ',' -v value=0 '{if ($2 != "") value++}END{printf("%d\n", value)}')
    missed_data=$((inf-month_known))
    max=$(echo "$INPUT" | awk -F ',' '{if ($2 != "") print $2}' | awk -F '-' '{print $1,$2}'| sort | uniq -c | sort -r | awk 'NR == 1{print$1}')
    echo "$INPUT" | awk -F ',' '{if ($2 != "") print $2}' | awk -F '-' '{print $1,$2}'| sort -n| uniq -c | awk -v width=$WIDTH -v graf_flag=$graf_flag -v missed_data=$missed_data -v max=$max '{
        if(!graf_flag) {
            printf("%s-%s: %d\n", $2, $3, $1)
        }
        else {
             if (width == 10000) {
                    new_width = 10000
                } else {
                    new_width = max/width
                }
            month_graf = int($1 / new_width)
                            printf("%s-%s: ", $2, $3)
                            for (i = 0; i < month_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
        }       
        }
        END {
            if(!graf_flag && missed_data != 0) {
            printf("None: %d\n", (missed_data))
        }
        else {
            if (width == 10000) {
                    new_width = 10000
                } else {
                    new_width = max/width
                }
            if(missed_data>0) {
                    n_graf = int(missed_data / new_width)
                            printf("None: ")
                            for (i = 0; i < n_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }
            }  
        }'
    invalid_data_printing

# yearly
    elif [ "$COMMAND" = "yearly" ]; then 
    if [[ $WIDTH == 0 ]]; then
		WIDTH=100000
	fi
    inf=$(echo "$INPUT" | awk 'END {print NR}')
    year_known=$(echo "$INPUT" | awk -F ',' -v value=0 '{if ($2 != "") value++}END{printf("%d\n", value)}')
    missed_data=$((inf-year_known))
    max=$(echo "$INPUT" | awk -F ',' '{if ($2 != "") print $2}' | awk -F '-' '{print $1}'| sort | uniq -c | sort -r | awk 'NR == 1{print$1}')
    echo "$INPUT" | awk -F ',' '{if ($2 != "") print $2}' | awk -F '-' '{print $1}'| sort -n| uniq -c |awk -v width=$WIDTH -v graf_flag=$graf_flag -v missed_data=$missed_data -v max=$max '{
        if(!graf_flag) {
                printf("%s: %d\n", $2, $1)
        }
        else {
            if (width == 100000) {
                    new_width = 100000
                } else {
                    new_width = max/width
                }
            year_graf = int($1 / new_width)
                printf("%s: ", $2)
                for (i = 0; i < year_graf; i++) {
                    printf("#")
                    }
                printf("\n")
        }
        }
        END {
            if(!graf_flag && missed_data != 0) {
            printf("None: %d\n", (missed_data))
        }
        else {
            if (width == 100000) {
                    new_width = 100000
                } else {
                    new_width = max/width
                }
            if(missed_data>0) {
                    n_graf = int(missed_data / new_width)
                            printf("None: ")
                            for (i = 0; i < n_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }
            }     
        }' 
    invalid_data_printing

# countries
    elif [ "$COMMAND" = "countries" ]; then 
    if [[ $WIDTH == 0 ]]; then
		WIDTH=100
	fi
    max=$(echo "$INPUT" | awk -F ',' '{if ($8 != "") print $8}' | awk -F '-' '{print $1}'| sort | uniq -c | sort -r | awk 'NR == 1{print$1}')
    echo "$INPUT" | awk -F ',' '{if ($8 ~ /^[A-Z]{2}$/ && $7 ~ /1/) print $8}' | sort | uniq -c | awk -v width=$WIDTH -v graf_flag=$graf_flag -v max=$max '{
        if(!graf_flag) {
            printf("%s: %d\n", $2, $1)
        }
        else {
            if (width == 100) {
                    new_width = 100
                } else {
                    new_width = max/width
                }
            countries_graf = int($1 / new_width)
                printf("%s: ", $2)
                for (i = 0; i < countries_graf; i++) {
                     printf("#")
                }
                printf("\n")
        } 
    }'
    invalid_data_printing

# districts
    elif [ "$COMMAND" = "districts" ]; then 
    if [[ $WIDTH == 0 ]]; then
		WIDTH=1000
	fi
    inf=$(echo "$INPUT" | awk 'END {print NR}')
    district_known=$(echo "$INPUT" | awk -F ',' -v value=0 '{if ($6 ~ /^[CZ]{2}[0-9,A-Z]{4}$/) value++}END{printf("%d\n", value)}')
    missed_data=$((inf-district_known))
    max=$(echo "$INPUT" | awk -F ',' '{if ($6 != "") print $6}' | awk -F '-' '{print $1}'| sort | uniq -c | sort -r | awk 'NR == 1{print$1}')
    INPUT=$(echo "$INPUT" | awk -F ',' '{if ($6 ~ /^[CZ]{2}[0-9,A-Z]{4}$/) print $6}' | sort | uniq -c)  
    echo "$INPUT" | awk -v width=$WIDTH -v graf_flag=$graf_flag -v missed_data=$missed_data -v max=$max '{
        if(!graf_flag) {
            printf("%s: %d\n", $2, $1) 
        }
        else {
            if (width == 1000) {
                    new_width = 1000
                } else {
                    new_width = max/width
                }
            districts_graf = int($1 / new_width)
                printf("%s: ", $2)
                for (i = 0; i < districts_graf; i++) {
                    printf("#")
                }
                printf("\n")
        }
        }
        END {
            if(!graf_flag && missed_data != 0) {
            printf("None: %d\n", missed_data)
        }
        else {
            if (width == 1000) {
                    new_width = 1000
                } else {
                    new_width = max/width
                }
            if(missed_data>0) {
                    n_graf = int(missed_data / new_width)
                            printf("None: ")
                            for (i = 0; i < n_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }
            }     
        }'  
        invalid_data_printing

# regions
    elif [ "$COMMAND" = "regions" ]; then 
    if [[ $WIDTH == 0 ]]; then
		WIDTH=10000
	fi
    inf=$(echo "$INPUT" | awk 'END {print NR}')
    region_known=$(echo "$INPUT" | awk -F ',' -v value=0 '{if ($5 ~ /^[CZ]{2}[0-9]{3}$/) value++}END{printf("%d\n", value)}')
    missed_data=$((inf-region_known))
    max=$(echo "$INPUT" | awk -F ',' '{if ($5 != "") print $5}' | awk -F '-' '{print $1}'| sort | uniq -c | sort -r | awk 'NR == 1{print$1}')
    INPUT=$(echo "$INPUT" | awk -F ',' '{if ($5 ~ /^[CZ]{2}[0-9]{3}$/) print $5}' | sort | uniq -c) 
    echo "$INPUT" | awk -v width=$WIDTH -v graf_flag=$graf_flag -v missed_data=$missed_data -v max=$max '{
        if(!graf_flag) {
            printf("%s: %d\n", $2, $1) 
        }
        else {
             if (width == 10000) {
                    new_width = 10000
                } else {
                    new_width = max/width
                }
            regions_graf = int($1 / new_width)
                            printf("%s: ", $2)
                            for (i = 0; i < regions_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
        }
        }
        END {
            if(!graf_flag && missed_data != 0) {
            printf("None: %d\n", (missed_data))
        }
        else {
            if(missed_data>0) {
                 if (width == 10000) {
                    new_width = 10000
                } else {
                    new_width = max/width
                }
                    n_graf = int(missed_data / new_width)
                            printf("None: ")
                            for (i = 0; i < n_graf; i++) {
                                printf("#")
                            }
                            printf("\n")
                }
            }     
        }'  
        invalid_data_printing
 fi
