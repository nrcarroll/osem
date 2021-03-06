# frozen_string_literal: true

require 'spec_helper'

feature Conference do

  let!(:conference) { create(:conference) }
  let!(:organizer_role) { Role.find_by(name: 'organizer', resource: conference) }
  let!(:organizer) { create(:user, role_ids: [organizer_role.id]) }

  shared_examples 'add and update cfp' do
    scenario 'adds a new cfp', feature: true, js: true do
      expected_count = Cfp.count + 1

      sign_in organizer

      visit new_admin_conference_program_cfp_path(conference.short_title)

      click_button 'Create Cfp'

      page.find('#flash')
      expect(flash)
          .to eq('Creating the call for papers failed. ' +
          "Start date can't be blank. End date can't be blank.")

      today = Date.today - 1
      page.execute_script(
      "$('#registration-period-start-datepicker').val('#{today.strftime('%d/%m/%Y')}')")
      page.execute_script(
      "$('#registration-period-end-datepicker').val('#{(today + 6).strftime('%d/%m/%Y')}')")

      click_button 'Create Cfp'

      # Validations
      expect(flash)
          .to eq('Call for papers successfully created.')

      visit admin_conference_program_cfp_path(conference.short_title, conference.program.cfp)
      expect(find('#start_date').text).to eq(today.strftime('%A, %B %-d. %Y'))
      expect(find('#end_date').text).to eq((today + 6).strftime('%A, %B %-d. %Y'))

      expect(Cfp.count).to eq(expected_count)
    end

    scenario 'update cfp', feature: true, js: true do
      create(:cfp, program: conference.program)
      expected_count = Cfp.count

      sign_in organizer
      visit admin_conference_program_cfp_path(conference.short_title, conference.program.cfp)
      click_link 'Edit'

      # Validate update with empty start date will not saved
      page.execute_script(
          "$('#registration-period-start-datepicker').val('')")
      click_button 'Update Cfp'
      page.find('#flash')
      expect(flash)
          .to eq('Updating call for papers failed. ' +
                    "Start date can't be blank.")

      # Fill in date
      today = Date.today - 9
      page.execute_script(
        "$('#registration-period-start-datepicker').val('#{today.strftime('%d/%m/%Y')}')")
      page.execute_script(
        "$('#registration-period-end-datepicker').val('#{(today + 14).strftime('%d/%m/%Y')}')")

      click_button 'Update Cfp'

      # Validations
      page.find('#flash')
      expect(flash)
          .to eq('Call for papers successfully updated.')

      visit admin_conference_program_cfp_path(conference.short_title, conference.program.cfp)
      expect(find('#start_date').text).to eq(today.strftime('%A, %B %-d. %Y'))
      expect(find('#end_date').text).to eq((today + 14).strftime('%A, %B %-d. %Y'))
      expect(Cfp.count).to eq(expected_count)
    end
  end

  describe 'organizer' do
    it_behaves_like 'add and update cfp'
  end
end
