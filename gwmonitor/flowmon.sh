#!/bin/ksh -x
##############################################################################################################################
# Script  : This script will track all files for error and send report of all transfer.
# Usage   : flowmon.sh [event/report]
# Version : 1.0 - 23/05/2018
# Author  : Sankar Mukherjee
##############################################################################################################################

## Utility Function
send_report(){

echo "INFO [$(date)] : Started Report Communication."
cat $scptHm/TEMPLATE/report.tmpl.header >> ${report_mail_file}
starttime=$(echo ${rpt_invl_srt} | tr " " ":")
endtime=$(echo ${rpt_invl_end} | tr " " ":")
sed -i 's/@@@START_TIME@@@/'${starttime}'/g' ${report_mail_file}
sed -i 's/@@@END_TIME@@@/'${endtime}'/g' ${report_mail_file}
sed -i 's/@@@MFT_OWNER@@@/'${mft_mail}'/g' ${report_mail_file}
sed -i 's/@@@USER_OWNER@@@/'${user_mail}'/g' ${report_mail_file}
cat ${report_detail_file} >> ${report_mail_file}
cat $scptHm/TEMPLATE/report.tmpl.footer >> ${report_mail_file}
echo "INFO [$(date)] : Prepared mail file now starting to send mail."
(
        echo To: ${user_mail}
        echo From: MFTAdmin
        echo "Content-Type: text/html; "
        echo "Subject: REPORT - GATEWAY - File Transfer."
        echo ""
	cat ${report_mail_file}
) | /usr/sbin/sendmail -t
echo "INFO [$(date)] : Completed Report Communication."

}

send_alert(){

echo "INFO [$(date)] : Started Alert Notification."
cat $scptHm/TEMPLATE/event.tmpl.header >> ${event_mail_file}
starttime=$(echo ${alrt_invl_srt} | tr " " ":")
endtime=$(echo ${alrt_invl_end} | tr " " ":")
sed -i 's/@@@START_TIME@@@/'${starttime}'/g' ${event_mail_file}
sed -i 's/@@@END_TIME@@@/'${endtime}'/g' ${event_mail_file}
sed -i 's/@@@MFT_OWNER@@@/'${mft_mail}'/g' ${event_mail_file}
sed -i 's/@@@USER_OWNER@@@/'${user_mail}'/g' ${event_mail_file}
cat ${event_detail_file} >> ${event_mail_file}
cat $scptHm/TEMPLATE/event.tmpl.footer >> ${event_mail_file}
echo "INFO [$(date)] : Prepared mail file now starting to send mail."
(
        echo To: ${mft_mail},${user_mail}
        echo From: MFTAdmin
        echo "Content-Type: text/html; "
        echo "Subject: ALERT - GATEWAY - Failed File Transfer."
        echo ""
        cat ${event_mail_file}
) | /usr/sbin/sendmail -t
echo "INFO [$(date)] : Completed Alert Notification."

}

generate_report(){

echo "INFO [$(date)] : Started Report Generation."
echo "INFO [$(date)] : Checking INBOUND Flows."
for flow_typ in $(grep "transf.inbound" $scptHm/monitor.conf | awk -F"." '{ print $3 }' | sort | uniq)
do
        echo "INFO [$(date)] : Checking INBOUND ${flow_typ} Flows."
        for flow_id in $(grep "transf.inbound.${flow_typ}" $scptHm/monitor.conf | awk -F"." '{ print $4 }' | awk -F"=" '{ print $1 }' | sort | uniq)
        do
                echo "INFO [$(date)] : Checking INBOUND ${flow_typ} for ${flow_id} Flows."
                flw_orign=$(grep "transf.inbound.${flow_typ}.${flow_id}" $scptHm/monitor.conf | awk -F"=" '{ print $2 }' | awk -F"," '{ print $1 }')
                flw_file=$(grep "transf.inbound.${flow_typ}.${flow_id}" $scptHm/monitor.conf | awk -F"=" '{ print $2 }' | awk -F"," '{ print $2 }')
                echo "INFO [$(date)] : Checking INBOUND ${flow_typ} for ${flow_id} for originator ${flw_orign} with file id ${flw_file}."
		tot_flow=$(peldsp select_trans -fd "${rpt_invl_srt}" -td "${rpt_invl_end}" -dir I -org "${flw_orign}" -pr SFTP -fn "${flw_file}" | wc -l)
		scount=0
		peldsp select_trans -fd "${rpt_invl_srt}" -td "${rpt_invl_end}" -dir I -org "${flw_orign}" -pr SFTP -lts E -lrs R -fn "${flw_file}" | while read tid
		do
			rtrans=$(peldsp display_trans -i ${tid} | grep "x_route_to_xfer=" | awk -F"=" '{ print $2 }' | tr -d "'")
			peldsp display_trans -i ${rtrans} | grep "x_state=" | grep -q "E"
			scount=$(expr $scount + 1)
		done
		echo "<tr><td style=\"width:10%\">${flow_typ}</td><td style=\"width:20%\">${flow_id}</td><td style=\"width:10%\">INBOUND</td><td style=\"width:20%\">${tot_flow}</td><td style=\"width:20%\">$(expr $tot_flow - $scount)</td></tr>" >> ${report_detail_file}
                echo "INFO [$(date)] : Completed INBOUND ${flow_typ} for ${flow_id} for originator ${flw_orign} with file id ${flw_file}."
                echo "INFO [$(date)] : Completed INBOUND ${flow_typ} for ${flow_id} Flows."
        done
        echo "INFO [$(date)] : Completed INBOUND ${flow_typ} Flows."
done
echo "INFO [$(date)] : Completed INBOUND Flows."
echo "INFO [$(date)] : Checking OUTBOUND Flows."
for flow_typ in $(grep "transf.outbound" $scptHm/monitor.conf | awk -F"." '{ print $3 }' | sort | uniq)
do
        echo "INFO [$(date)] : Checking OUTBOUND ${flow_typ} Flows."
        for flow_id in $(grep "transf.outbound.${flow_typ}" $scptHm/monitor.conf | awk -F"." '{ print $4 }' | awk -F"=" '{ print $1 }' | sort | uniq)
        do
                echo "INFO [$(date)] : Checking OUTBOUND ${flow_typ} for ${flow_id} Flows."
                flw_orign=$(grep "transf.outbound.${flow_typ}.${flow_id}" $scptHm/monitor.conf | awk -F"=" '{ print $2 }' | awk -F"," '{ print $1 }')
                flw_file=$(grep "transf.outbound.${flow_typ}.${flow_id}" $scptHm/monitor.conf | awk -F"=" '{ print $2 }' | awk -F"," '{ print $2 }')
                echo "INFO [$(date)] : Checking OUTBOUND ${flow_typ} for ${flow_id} for originator ${flw_orign} with file id ${flw_file}."
		tot_flow=$(peldsp select_trans -fd "${rpt_invl_srt}" -td "${rpt_invl_end}" -dir O -org "${flw_orign}" -pr SFTP -fn "${flw_file}" | wc -l)
                tot_succs=$(peldsp select_trans -fd "${rpt_invl_srt}" -td "${rpt_invl_end}" -dir O -org "${flw_orign}" -pr SFTP -lts "E" -fn "${flw_file}" | wc -l)
		echo "<tr><td style=\"width:10%\">${flow_typ}</td><td style=\"width:20%\">${flow_id}</td><td style=\"width:20%\">OUTBOUND</td><td style=\"width:20%\">${tot_flow}</td><td style=\"width:20%\">$(expr $tot_flow - $tot_succs)</td></tr>" >> ${report_detail_file}
                echo "INFO [$(date)] : Completed OUTBOUND ${flow_typ} for ${flow_id} for originator ${flw_orign} with file id ${flw_file}."
                echo "INFO [$(date)] : Completed OUTBOUND ${flow_typ} for ${flow_id} Flows."
        done
        echo "INFO [$(date)] : Completed OUTBOUND ${flow_typ} Flows."
done
echo "INFO [$(date)] : Completed OUTBOUND Flows."
send_report
echo "INFO [$(date)] : Completed Report Generation."

}

check_alert(){

echo "INFO [$(date)] : Started Alert Validation."
is_failure="false"
echo "INFO [$(date)] : Checking INBOUND Flows."
for flow_typ in $(grep "transf.inbound" $scptHm/monitor.conf | awk -F"." '{ print $3 }' | sort | uniq)
do
	echo "INFO [$(date)] : Checking INBOUND ${flow_typ} Flows."
	for flow_id in $(grep "transf.inbound.${flow_typ}" $scptHm/monitor.conf | awk -F"." '{ print $4 }' | awk -F"=" '{ print $1 }' | sort | uniq)
	do
		echo "INFO [$(date)] : Checking INBOUND ${flow_typ} for ${flow_id} Flows."
		flw_orign=$(grep "transf.inbound.${flow_typ}.${flow_id}" $scptHm/monitor.conf | awk -F"=" '{ print $2 }' | awk -F"," '{ print $1 }')
		flw_file=$(grep "transf.inbound.${flow_typ}.${flow_id}" $scptHm/monitor.conf | awk -F"=" '{ print $2 }' | awk -F"," '{ print $2 }')
		echo "INFO [$(date)] : Checking INBOUND ${flow_typ} for ${flow_id} for originator ${flw_orign} with file id ${flw_file}."
		peldsp select_trans -fd "${alrt_invl_srt}" -td "${alrt_invl_end}" -dir I -org "${flw_orign}" -pr SFTP -fn "${flw_file}" |while read tansid
		do
			trans_detail=$(peldsp display_trans -i ${tansid} | tr "\n" ";")
			trans_state=$(echo $trans_detail | awk -F"x_state=" '{ print $2 }' | awk -F";" '{ print $1 }' | tr -d "'")
                        rout_state=$(echo $trans_detail | awk -F"x_route_state=" '{ print $2 }' | awk -F";" '{ print $1 }' | tr -d "'")
			trans_date=$(echo $trans_detail | awk -F"x_date_end=" '{ print $2 }' | awk -F";" '{ print $1 }' | tr -d "'")
			trans_file=$(echo $trans_detail | awk -F"x_file_name=" '{ print $2 }' | awk -F";" '{ print $1 }' | tr -d "'")
			echo "INFO [$(date)] : FLOW ${flow_id} ID ${tansid} DATE ${trans_date} STATE ${trans_state} ROUTE ${rout_state} FILE ${trans_file}."
			if [ "${trans_state}" != "E" ] ; then
                                echo "<tr><td style=\"width:10%\">${flow_typ}</td><td style=\"width:20%\">${flow_id}</td><td style=\"width:10%\">INBOUND</td><td style=\"width:20%\">${trans_file}</td><td style=\"width:10%\">${tansid}</td><td style=\"width:20%\">${trans_date}</td><td style=\"width:20%\">GATEWAY TRANSFER FAILURE</td></tr>" >> ${event_detail_file}
				is_failure="true"
			elif [ "${rout_state}" != "ROUTED" ] ; then
				echo "<tr><td style=\"width:10%\">${flow_typ}</td><td style=\"width:20%\">${flow_id}</td><td style=\"width:10%\">INBOUND</td><td style=\"width:20%\">${trans_file}</td><td style=\"width:10%\">${tansid}</td><td style=\"width:20%\">${trans_date}</td><td style=\"width:20%\">GATEWAY ROUTING FAILURE</td></tr>" >> ${event_detail_file}
				is_failure="true"
			else
				route_id=$(echo $trans_detail | awk -F"x_route_to_xfer=" '{ print $2 }' | awk -F";" '{ print $1 }' | tr -d "'")
				peldsp display_trans -i ${route_id} | grep "x_state=" | grep -q "E"
				if [ $? -ne 0 ] ; then
					echo "<tr><td style=\"width:10%\">${flow_typ}</td><td style=\"width:10%\">${flow_id}</td><td style=\"width:10%\">INBOUND</td><td style=\"width:20%\">${trans_file}</td><td style=\"width:10%\">${tansid}</td><td style=\"width:20%\">${trans_date}</td><td style=\"width:20%\">CFT TRANSFER FAILURE</td></tr>" >> ${event_detail_file}
					is_failure="true"
				fi
			fi
		done
                echo "INFO [$(date)] : Completed INBOUND ${flow_typ} for ${flow_id} for originator ${flw_orign} with file id ${flw_file}."
                echo "INFO [$(date)] : Completed INBOUND ${flow_typ} for ${flow_id} Flows."
	done
        echo "INFO [$(date)] : Completed INBOUND ${flow_typ} Flows."
done
echo "INFO [$(date)] : Completed INBOUND Flows."
echo "INFO [$(date)] : Checking OUTBOUND Flows."
for flow_typ in $(grep "transf.outbound" $scptHm/monitor.conf | awk -F"." '{ print $3 }' | sort | uniq)
do
        echo "INFO [$(date)] : Checking OUTBOUND ${flow_typ} Flows."
        for flow_id in $(grep "transf.outbound.${flow_typ}" $scptHm/monitor.conf | awk -F"." '{ print $4 }' | awk -F"=" '{ print $1 }' | sort | uniq)
        do
                echo "INFO [$(date)] : Checking OUTBOUND ${flow_typ} for ${flow_id} Flows."
                flw_orign=$(grep "transf.outbound.${flow_typ}.${flow_id}" $scptHm/monitor.conf | awk -F"=" '{ print $2 }' | awk -F"," '{ print $1 }')
                flw_file=$(grep "transf.outbound.${flow_typ}.${flow_id}" $scptHm/monitor.conf | awk -F"=" '{ print $2 }' | awk -F"," '{ print $2 }')
                echo "INFO [$(date)] : Checking OUTBOUND ${flow_typ} for ${flow_id} for originator ${flw_orign} with file id ${flw_file}."
                peldsp select_trans -fd "${alrt_invl_srt}" -td "${alrt_invl_end}" -dir O -org "${flw_orign}" -pr SFTP -lts "CFIS" -fn "${flw_file}" |while read tansid
                do
                        trans_detail=$(peldsp display_trans -i ${tansid} | tr "\n" ";")
                        trans_date=$(echo $trans_detail | awk -F"x_date_end=" '{ print $2 }' | awk -F";" '{ print $1 }' | tr -d "'")
                        trans_file=$(echo $trans_detail | awk -F"x_file_name=" '{ print $2 }' | awk -F";" '{ print $1 }' | tr -d "'")
			echo "INFO [$(date)] : FLOW ${flow_id} ID ${tansid} DATE ${trans_date} FILE ${trans_file}."
			echo "<tr><td style=\"width:10%\">${flow_typ}</td><td style=\"width:10%\">${flow_id}</td><td style=\"width:10%\">OUTBOUND</td><td style=\"width:20%\">${trans_file}</td><td style=\"width:10%\">${tansid}</td><td style=\"width:20%\">${trans_date}</td><td style=\"width:20%\">GATEWAY TRANSFER FAILURE</td></tr>" >> ${event_detail_file}
			is_failure="true"
                done
                echo "INFO [$(date)] : Completed OUTBOUND ${flow_typ} for ${flow_id} for originator ${flw_orign} with file id ${flw_file}."
                echo "INFO [$(date)] : Completed OUTBOUND ${flow_typ} for ${flow_id} Flows."
        done
        echo "INFO [$(date)] : Completed OUTBOUND ${flow_typ} Flows."
done
echo "INFO [$(date)] : Completed OUTBOUND Flows."
if [ "${is_failure}" == "true" ] ; then
	send_alert	
fi
echo "INFO [$(date)] : Completed Alert Validation."

}

mode=$1
[ "${mode}" != "event" -a "${mode}" != "report" ] && mode="event"
scptHm=$(cd $(dirname $0);pwd)
usrHm=$(echo $HOME)
source ${usrHm}/.profile

echo "INFO [$(date)] : Started flowmon.sh on $(hostname) with mode ${mode}."

user_mail=$(grep admin.user.mail $scptHm/monitor.conf | cut -d= -f2-)
mft_mail=$(grep admin.mft.mail $scptHm/monitor.conf | cut -d= -f2-)
report_mft=$(grep admin.report.mail.mft $scptHm/monitor.conf | cut -d= -f2-)
report_intervl=$(grep admin.report.interval $scptHm/monitor.conf | cut -d= -f2-)
event_intervl=$(grep admin.event.interval $scptHm/monitor.conf | cut -d= -f2-)
reprt_err_wt=10

echo "INFO [$(date)] : Property User $user_mail, MFT Admin $mft_mail, Report MFT Admin $report_mft, Report Interval $report_intervl, Event Interval $event_intervl."

[ ! -d ${scptHm}/TMP/ ] && mkdir -p ${scptHm}/TMP/
report_mail_file=${scptHm}/TMP/mail.report.$$.tmp
report_detail_file=${scptHm}/TMP/detail.report.$$.tmp
event_mail_file=${scptHm}/TMP/mail.event.$$.tmp
event_detail_file=${scptHm}/TMP/detail.event.$$.tmp
report_list_tmp=${scptHm}/TMP/report.list.$$.tmp
alrt_invl_srt=$(date +"%Y%m%d %H%M%S" -d "${event_intervl} min ago")
alrt_invl_end=$(date +"%Y%m%d %H%M%S")
rpt_invl_srt=$(date +"%Y%m%d %H%M%S" -d "${report_intervl} min ago")
rpt_invl_end=$(date +"%Y%m%d %H%M%S")
echo "INFO [$(date)] : Monitor interval for Alert Start $alrt_invl_srt End $alrt_invl_end, Report Start $rpt_invl_srt End $rpt_invl_end ."
echo "INFO [$(date)] : Mail Report file $report_mail_file, Event file $event_mail_file ."

if [ "${mode}" == "event" ] ; then
	check_alert
elif [ "${mode}" == "report" ] ; then
        generate_report
fi

rm -f ${scptHm}/TMP/*.$$.tmp
echo "INFO [$(date)] : Completed flowmon.sh on $(hostname) with mode ${mode}."
