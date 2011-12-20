require File.dirname(__FILE__) + '/../../test_helper'

class Groups::WikisControllerTest < ActionController::TestCase

  def setup
    @user = User.make
    @group = Group.make
    @group.add_user!(@user)
  end

  def test_new
    login_as @user
    assert_permission :may_create_group_wiki? do
      xhr :get, :new, :group_id => @group.to_param
    end
    assert_response :success
    assert assigns['wiki'].new_record?
  end

  def test_new_private_wiki
    login_as @user
    xhr :get, :new, :group_id => @group.to_param, :private => true
    assert_response :success
    assert assigns['wiki'].new_record?
    assert_select 'input#wiki_private[type="hidden"][value="true"]'
  end

  def test_new_with_existing_wiki
    login_as @user
    @wiki = @group.profiles.public.create_wiki :body => 'init'
    xhr :get, :new, :group_id => @group.to_param
    assert_response :success
    assert !assigns['wiki'].new_record?
    assert_equal @wiki, assigns['wiki']
  end

  def test_new_with_existing_private_wiki
    login_as @user
    @wiki = @group.profiles.private.create_wiki :body => 'init'
    xhr :get, :new, :group_id => @group.to_param, :private => true
    assert_response :success
    assert !assigns['wiki'].new_record?
    assert_equal @wiki, assigns['wiki']
  end

  def test_new_private_with_existing_public_wiki
    login_as @user
    @wiki = @group.profiles.public.create_wiki :body => 'init'
    xhr :get, :new, :group_id => @group.to_param, :private => true
    assert_response :success
    assert assigns['wiki'].new_record?
    assert_select 'input#wiki_private[type="hidden"][value="true"]'
  end

  def test_create_private
    login_as @user
    assert_permission :may_create_group_wiki? do
      xhr :post, :create,
        :group_id => @group.to_param,
        :wiki => { :body => "_created_", :private => true }
    end
    wiki = Wiki.last
    assert "<em>created</em>", wiki.body_html
    assert wiki.profile.private?
    assert_equal @user, wiki.versions.last.user
    assert_response :redirect
    assert_redirected_to group_url(@group)
  end

  def test_create_public
    login_as @user
    assert_permission :may_create_group_wiki? do
      xhr :post, :create,
        :group_id => @group.to_param,
        :wiki => { :body => "_created_", :private => false }
    end
    wiki = Wiki.last
    assert "<em>created</em>", wiki.body_html
    assert wiki.profile.public?
    assert_response :redirect
    assert_redirected_to group_url(@group)
  end

  def test_create_with_existing_wiki
    @wiki = @group.profiles.public.create_wiki :body => 'init'
    login_as @user
    assert_difference '@wiki.versions.count' do
      xhr :post, :create,
        :group_id => @group.to_param,
        :wiki => { :body => "_created_", :private => false }
    end
    wiki = Wiki.last
    assert "<em>created</em>", wiki.body_html
    assert wiki.profile.public?
    assert_response :redirect
    assert_redirected_to group_url(@group)
  end

  def test_show_private
    @wiki = @group.profiles.private.create_wiki :body => 'init'
    login_as @user
    assert_permission :may_show_group_wiki? do
      xhr :get, :show, :group_id => @group.to_param, :id => @wiki.id
    end
    assert_response :success
    assert_equal @wiki, assigns['wiki']
  end

  def test_show_to_stranger
    @wiki = @group.profiles.public.create_wiki :body => 'init'
    assert_permission :may_show_group_wiki? do
      xhr :get, :show, :group_id => @group.to_param, :id => @wiki.id
    end
    assert_response :success
    assert_equal @wiki, assigns['wiki']
  end

  def test_do_not_show_private_to_stranger
    @priv = @group.profiles.private.create_wiki :body => 'private'
    assert_permission(:may_show_group_wiki?, false) do
      xhr :get, :show, :group_id => @group.to_param, :id => @priv.id
    end
  end

end
