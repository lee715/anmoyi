errs = 
  failed: 
    code: 400301
    msg: 'failed, pelease try later.'
  missParams: 
    code: 400302
    msg: 'lack of paramaters'
  unvalidPhone:
    code: 400303
    msg: 'unvalid phone number'
  permissionDenied:
    code: 401300
    msg: 'permission denied'
  unknown:
    code: 400400
    msg: 'unknown error'
  SystemBusy:
    code: 400304
    msg: 'system busy.Pelease try later.'

module.exports = (str) ->
  errs[str] or errs.unknown