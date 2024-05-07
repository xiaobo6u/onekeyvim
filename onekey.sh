#!/bin/bash  
  
# 假设INI文件名为config.ini  
ini_file="config.ini"  
  
# 初始化section名称变量  
current_section=""
TOOLS="tools"
VIMDIR=${HOME}/.vim
VIMRC=${VIMDIR}rc
globalgz=global-6.6.12


# 首先安装global环境
function global_first() {  
	# 首先编译安装global
	oldir=`pwd`
	glb_nm=${1}
	glb_src=$TOOLS/$glb_nm.tar.gz
	glb_dst=$glb_nm
	tar axf $glb_src
	cd $glb_dst
	./configure --with-sqlite3   # gtags可以使用Sqlite3作为数据库, 在编译时需要加这个参数
	make -j6
	sudo make install
	cp -f gtags-cscope.vim  gtags.vim ~/.vim/plugin/
	cd $oldir
	rm -rf $glb_dst
}


# 检查指定tools文件夹下是否存在以给定section开头的文件  
function check_tools_for_section() {  
	local current_section=$1    
	# 使用find命令查找以current_section开头的cfg文件  
	local cfgfile=$(find "$TOOLS" -type f -name "${current_section}*.cfg" 2>/dev/null)  
	if [[ -n "$cfgfile" ]]; then
		echo "找到 $cfgfile"
		cat $cfgfile >> $VIMRC
	fi  
	# 使用find命令查找以current_section开头的zip文件  
	local zipfile=$(find "$TOOLS" -type f -name "${current_section}*.zip" 2>/dev/null)  	
	if [[ -n "$zipfile" ]]; then
		filename_with_ext=$(basename "$zipfile")  
		filename_without_ext="${filename_with_ext%.*}"
		#rm -rf $filename_without_ext
		unzip -x -o -q "$zipfile" -d $filename_without_ext
		if [ -e $filename_without_ext/$filename_without_ext ];then
			cp -rf $filename_without_ext/$filename_without_ext/* ${VIMDIR}
		else
			cp -rf $filename_without_ext/* ${VIMDIR}
		fi
		rm -rf $filename_without_ext
	fi  
}

rm -rf ${VIMDIR}; mkdir -p $VIMDIR/plugin
rm -rf $VIMRC   ; touch $VIMRC
# 首先安装global环境
global_first $globalgz

# 遍历INI文件的每一行  
while IFS= read -r line || [[ -n "$line" ]]; do  
	# 去除行首和行尾的空白字符  
	trimmed_line=$(echo "$line" | xargs)  
  
	# 检查当前行是否是一个新的section  
	if [[ "$trimmed_line" =~ ^\[[^]]+\]$ ]]; then  
		# 提取section名称（去掉[和]）  
		current_section=${trimmed_line#\[}  
		current_section=${current_section%\]}  
		# 重置enable字段的值为空，以便开始检查新的section  
		enable_value=""  
	elif [[ -n "$current_section" && "$trimmed_line" =~ ^enable=.*$ ]]; then  
		# 如果当前行是一个键值对，并且键是enable，则提取其值  
		enable_key_value=(${trimmed_line//=/ })  
		if [[ "${enable_key_value[0]}" == "enable" ]]; then  
			enable_value="${enable_key_value[1]}"  
			# 检查enable字段的值是否为true  
			if [[ "$enable_value" == "true" ]]; then
				check_tools_for_section $current_section
			fi  
		fi  
	fi  
done < "$ini_file"  
  
# 脚本结束
