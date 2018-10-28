import Ember from 'ember';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  classNames: ['create-review'],

  actions: {
    submit: function() {
      const reviewTitle = $('.review-title').val();
      const reviewCategories = $('.review-categories').children(':first').data('value');
      const reviewFeaturedBadge = $('.review-featured-badge').val();
      const reviewStart = $('.review-start .date-picker').val();
      const reviewEnd = $('.review-end .date-picker').val();
      const reviewPublishCategory = $('.review-publish-category').val();

      console.log('review title', reviewTitle);
      console.log('review categories', reviewCategories);
      console.log('review featured badge', reviewFeaturedBadge);
      console.log('review start', reviewStart);
      console.log('review end', reviewEnd);
      console.log('review publish category', reviewPublishCategory);

      ajax("/admin/plugins/yearly-review/create.json", {
        type: "POST",
        data: {
          review_title: reviewTitle,
          review_categories: reviewCategories,
          review_featured_badge: reviewFeaturedBadge,
          review_start: reviewStart,
          review_end: reviewEnd,
          review_publish_category: reviewPublishCategory
        }
      }).then(() => {
        bootbox.alert(I18n.t('yearly_review.report_created'));
      }).catch(popupAjaxError);
    },
  }
});
