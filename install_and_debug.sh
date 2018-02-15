set -x

usage() { echo "Usage: $0 -i <IP|HOSTNAME> -u <USERNAME>" 1>&2; exit 1; }



while getopts ":i:u:" opt; do
  case ${opt} in
    i)
      IP=${OPTARG}
      ;;
    u) 
      USERNAME=${OPTARG}
      ;;
    \? )
      echo "Invalid option: -$OPTARG"
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${IP}" ] || [ -z "${USERNAME}" ]; then
    usage
fi


./script_install.sh -i ${IP} -u ${USERNAME} | tee debug.log