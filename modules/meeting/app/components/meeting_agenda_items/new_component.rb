#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module MeetingAgendaItems
  class NewComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, meeting_agenda_item: nil, hidden: true, type: :simple)
      super

      @meeting = meeting
      @meeting_agenda_item = meeting_agenda_item || MeetingAgendaItem.new(meeting:, author: User.current)
      @hidden = hidden
      @type = type
    end

    def call
      component_wrapper do
        unless @hidden
          form_partial
        end
      end
    end

    private

    def form_partial
      render(Primer::Box.new(border: :top)) do
        render(Primer::Box.new(p: 3)) do
          render(MeetingAgendaItems::FormComponent.new(
                   meeting: @meeting,
                   meeting_agenda_item: @meeting_agenda_item,
                   method: :post,
                   submit_path: meeting_agenda_items_path(@meeting, format: :turbo_stream),
                   cancel_path: cancel_new_meeting_agenda_items_path(@meeting),
                   type: @type
                 ))
        end
      end
    end
  end
end
