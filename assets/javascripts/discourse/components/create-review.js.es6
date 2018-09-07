import Ember from 'ember';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  classNames: ['create-review'],

  actions: {
    submit() {
      ajax("/admin/plugins/yearly-review/create.json", {
        type: "POST",
        data: {}
      }).then(() => {
        bootbox.alert(I18n.t('yearly_review.report_created'));
      }).catch(popupAjaxError);
    },
  }
});
