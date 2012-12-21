#include <stdlib.h>

#include "STAF.h"
#include <ruby.h>

static VALUE rb_eSTAFException;
static VALUE rb_eSTAFInvalidObjectException;
static VALUE rb_eSTAFInvalidParmException;
static VALUE rb_eSTAFBaseOSErrorException;
static VALUE rb_cSTAFResult;

static VALUE rb_cSTAFHandle;

void sh_free(void *p) {
  STAFHandle_t *handle = (STAFHandle_t*)p;
  STAFRC_t rc;
  rc = STAFUnRegister(*handle);
  free(handle);
}

VALUE checkForExceptions(STAFRC_t rc, char *result)
{
  VALUE exception = Qnil;
  VALUE args[3];
  int argc = 0;

  args[argc++] = INT2NUM(rc);
  if(result != NULL) {
    args[argc++] = rb_str_new2(result);
  }
  switch(rc) {
  case kSTAFInvalidObject:
    exception = rb_class_new_instance(argc, args, rb_eSTAFInvalidObjectException);
    break;
  case kSTAFInvalidParm:
    exception = rb_class_new_instance(argc, args, rb_eSTAFInvalidParmException);
    break;
  case kSTAFBaseOSError:
    exception = rb_class_new_instance(argc, args, rb_eSTAFBaseOSErrorException);
    break;
  case kSTAFUnknownService:
  case kSTAFUnknownError:
  case kSTAFNotRunning:
  case kSTAFRegistrationError:
  case kSTAFServiceNotAvailable:
    exception = rb_class_new_instance(argc, args, rb_eSTAFException);
  case kSTAFOk:
  default:
    break;
  }

  return exception;
}

static VALUE sh_init(int argc, VALUE *argv, VALUE self)
{
  VALUE name, handle, doUnreg = Qnil;

  rb_scan_args(argc, argv, "11", &name, &doUnreg);
  rb_iv_set(self, "@name", name);
  if(doUnreg == Qnil) {
    rb_iv_set(self, "@doUnreg", Qtrue);
  } else {
    rb_iv_set(self, "@doUnreg", Qfalse);
  }

  return self;
}


VALUE sh_new(int argc, VALUE *argv, VALUE class)
{
  VALUE rb_name, rb_handle, rb_unreg;
  VALUE trb_argv[2];
  VALUE tdata;

  STAFHandle_t *handle = NULL;

  tdata = Data_Make_Struct(class, STAFHandle_t, 0, sh_free, handle);
  *handle = 0; 

  rb_name = rb_handle = Qnil;
  rb_scan_args(argc, argv, "03", &rb_name, &rb_handle, &rb_unreg);
  if(rb_name == Qnil) {
    rb_name = rb_str_new2("STAF/RubyClient");
  }
  if(rb_handle == Qnil) {
    VALUE exception;
    STAFRC_t rc;
    VALUE rbname_for_cstr_cast = rb_str_dup(rb_name);
    rb_str_modify(rbname_for_cstr_cast);
    char *name = StringValuePtr(rbname_for_cstr_cast);    

    rc = STAFRegister(name, handle);
    if( (exception = checkForExceptions(rc, NULL)) != Qnil ) {
      rb_exc_raise(exception);
      return Qnil;
    }
  } else {
    *handle = NUM2INT(rb_handle);
  }
  
  trb_argv[0] = rb_name;
  trb_argv[1] = rb_unreg;

  rb_obj_call_init(tdata, 2, argv);

  return tdata;
}

VALUE sh_submit(VALUE self, 
		VALUE rb_where, VALUE rb_service, VALUE rb_request)
{
  VALUE rb_handle, exception;
  STAFHandle_t *handle;
  STAFRC_t rc;
  char *where, *service, *request;
  char *result;
  int resultlen;
  VALUE rb_result, args[2];
  int argc = 0;

  Data_Get_Struct(self, STAFHandle_t, handle);
  VALUE rbwhere_for_cstr_cast = rb_str_dup(rb_where);
  rb_str_modify(rbwhere_for_cstr_cast);
  where   = StringValuePtr(rbwhere_for_cstr_cast);
  VALUE rbservice_for_cstr_cast = rb_str_dup(rb_service);
  rb_str_modify(rbservice_for_cstr_cast);
  service = StringValuePtr(rbservice_for_cstr_cast);
  VALUE rbreq_for_cstr_cast = rb_str_dup(rb_request);
  rb_str_modify(rbreq_for_cstr_cast);
  request = StringValuePtr(rbreq_for_cstr_cast);

  rc = STAFSubmit(*handle, where, service, request, strlen(request),
		  &result, &resultlen);
  if( (exception = checkForExceptions(rc, result)) != Qnil ) {
    STAFFree(*handle, result);
    rb_exc_raise(exception);
    return Qnil;
  }

  args[argc++] = INT2NUM(rc);
  args[argc++] = rb_str_new(result, resultlen);
  rb_result = rb_class_new_instance(argc, args, rb_cSTAFResult);

  STAFFree(*handle, result);
  return rb_result;
}

VALUE sh_tos(VALUE self)
{
  STAFHandle_t *handle;
  char buf[32];

  Data_Get_Struct(self, STAFHandle_t, handle);
  sprintf(buf, "%d",(unsigned int)*handle);
  return rb_str_new2(buf);
}

void Init_STAFHandle()
{
  /* define a module named 'STAF' */
  VALUE module = rb_define_module("STAF");

  /* require helper classes */
  rb_require("./db_handler/staf/STAFException.rb");
  rb_require("./db_handler/staf/STAFResult.rb");

  /* get handles to those classes.
     the handles must be based on the STAF module, since that's
     where the classes are defined. */
  rb_eSTAFException = rb_const_get(module, rb_intern("STAFException"));
  rb_eSTAFInvalidObjectException = rb_const_get(module, rb_intern("STAFInvalidObjectException"));
  rb_eSTAFInvalidParmException = rb_const_get(module, rb_intern("STAFInvalidParmException"));
  rb_eSTAFBaseOSErrorException = rb_const_get(module, rb_intern("STAFBaseOSErrorException"));
  rb_cSTAFResult = rb_const_get(module, rb_intern("STAFResult"));
  
  /* define the STAFHandle class */ 
  rb_cSTAFHandle = rb_define_class_under(module, "STAFHandle", rb_cObject);
  rb_define_singleton_method(rb_cSTAFHandle, "new", sh_new, -1);
  rb_define_method(rb_cSTAFHandle, "initialize", sh_init, -1);
  rb_define_method(rb_cSTAFHandle, "submit", sh_submit, 3);
  rb_define_method(rb_cSTAFHandle, "to_s", sh_tos,0);
}
