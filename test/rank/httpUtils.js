const axios = require('axios');

/**
 * http post请求
 * @param {请求地址} url
 * @param {请求参数} data
 * @return
 */
module.exports.post = async function(url, data) {
    try{
        let result = axios.post(url,data,{
            Headers:{
                'Content-Type': 'application/json',
            }
        }
        ).then(res=>{
           return  res.data
        })
        
        return result
    } catch(e){
        if(e.status != 200){
            console.log('发送请求失败！ 错误信息：'+JSON.stringify(e))
        }
    }
    return null;
}



