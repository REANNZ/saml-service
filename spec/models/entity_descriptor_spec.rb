# frozen_string_literal: true

require 'rails_helper'

describe EntityDescriptor do
  it_behaves_like 'a basic model'

  it { is_expected.to validate_presence :known_entity }
  it { is_expected.to validate_presence :entity_id }
  it { is_expected.to validate_presence :role_descriptors }

  context 'at least one of' do
    it { is_expected.to have_one_to_many :role_descriptors }
    it { is_expected.to have_one_to_many :idp_sso_descriptors }
    it { is_expected.to have_one_to_many :sp_sso_descriptors }
    it { is_expected.to have_one_to_many :attribute_authority_descriptors }
  end

  context 'optional attributes' do
    it { is_expected.to have_many_to_one :organization }
    it { is_expected.to have_one_to_many :contact_people }
    it { is_expected.to have_one_to_many :sirtfi_contact_people }
    it { is_expected.to have_one_to_many :additional_metadata_locations }
    it { is_expected.to have_column :extensions, type: :text }

    it { is_expected.to have_one_to_one :registration_info }
    it { is_expected.to have_one_to_one :publication_info }
    it { is_expected.to have_one_to_one :entity_attribute }
  end

  context 'validation' do
    subject { create :entity_descriptor }

    context 'with a valid descriptor' do
      before { subject.add_role_descriptor create :role_descriptor }

      it 'is invalid without org, valid without contacts or srtifi contacts' do
        expect(subject.contact_people).not_to be_present
        expect(subject).to be_valid
        expect(subject.sirtfi_contact_people).not_to be_present
        expect(subject).to be_valid
        subject.organization = nil
        expect(subject).not_to be_valid
        expect(subject.entity_attribute?).to be_falsey
        subject.entity_attribute = create :mdattr_entity_attribute
        expect(subject.entity_attribute?).to be_truthy
      end
    end

    it 'is invalid without descriptors, valid with role_descriptor,' \
       'idp_sso_descriptor, attribute_authority_descriptor' do
      expect(subject).not_to be_valid
      subject.add_role_descriptor create :role_descriptor
      expect(subject).to be_valid
      subject.add_role_descriptor create :idp_sso_descriptor
      expect(subject).to be_valid
      subject.add_role_descriptor create :attribute_authority_descriptor
      expect(subject).to be_valid
      subject.add_role_descriptor create :sp_sso_descriptor
      expect(subject).to be_valid
    end
  end

  describe '#functioning?' do
    context 'when ED is valid' do
      let(:idp) { create :idp_sso_descriptor }
      subject { idp.entity_descriptor }

      before { subject.enabled = true }

      it 'is valid' do
        expect(subject).to be_valid
        expect(subject).to be_functioning
        subject.enabled = false
        expect(subject).not_to be_functioning
      end

      context 'without a functioning role descriptor' do
        before do
          subject.idp_sso_descriptors.first.update(enabled: false)
        end

        it 'is not functioning' do
          expect(subject).not_to be_functioning
        end
      end
    end

    context 'when ED is invalid' do
      subject { create :entity_descriptor }

      before do
        subject.enabled = true
      end

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject).not_to be_functioning
        subject.enabled = false
        expect(subject).not_to be_functioning
      end
    end
  end

  describe '#touch' do
    let(:role_descriptor) { create :role_descriptor }
    subject { role_descriptor.entity_descriptor }

    it 'modifies parent EntityDescriptor on save' do
      Timecop.travel(30.seconds) do
        expect { subject.touch }.to(change { subject.updated_at })
      end
    end
  end

  describe '#edugain_compliant?' do
    shared_examples 'edugain compliance' do
      context 'with technical contact' do
        before do
          cp = create :contact_person, contact_type: :technical
          subject.add_contact_person(cp)
        end

        it 'is edugain compliant' do
          expect(subject).to be_edugain_compliant
        end
      end

      context 'with support contact' do
        before do
          cp = create :contact_person, contact_type: :support
          subject.add_contact_person(cp)
        end

        it 'is edugain compliant' do
          expect(subject).to be_edugain_compliant
        end
      end

      context 'without technical or support contact' do
        before do
          cp = create :contact_person, contact_type: :administrative
          subject.add_contact_person(cp)
        end

        it 'is not edugain compliant' do
          expect(subject).not_to be_edugain_compliant
        end
      end

      context 'without any contacts' do
        it 'is not edugain compliant' do
          expect(subject).not_to be_edugain_compliant
        end
      end
    end

    context 'when referencing an IdP' do
      subject { idp.entity_descriptor }

      let(:idp) { create :idp_sso_descriptor, :with_ui_info }

      include_examples 'edugain compliance'
      context 'with active idps and contacts' do
        let(:another_idp) { create :idp_sso_descriptor, :with_ui_info }

        before do
          another_idp
          cp = create :contact_person, contact_type: :technical
          subject.add_contact_person(cp)
        end

        context 'without functioning IdP' do
          it 'is not edugain compliant' do
            subject.idp_sso_descriptors.first.update(enabled: false)
            expect(subject).not_to be_edugain_compliant
          end
        end

        context 'without IdP MDUI' do
          let(:idp) { create :idp_sso_descriptor }

          it 'is not edugain compliant' do
            expect(subject).not_to be_edugain_compliant
          end
        end
      end
    end

    context 'when referencing an SP' do
      subject { sp.entity_descriptor }

      let(:sp) { create :sp_sso_descriptor, :with_ui_info }

      include_examples 'edugain compliance'

      context 'with active idps and contacts' do
        let(:another_sp) { create :sp_sso_descriptor, :with_ui_info }

        before do
          another_sp
          cp = create :contact_person, contact_type: :technical
          subject.add_contact_person(cp)
        end

        context 'without functioning SP' do
          it 'is not edugain compliant' do
            subject.sp_sso_descriptors.first.update(enabled: false)
            expect(subject).not_to be_edugain_compliant
          end
        end

        context 'without SP MDUI' do
          let(:sp) { create :sp_sso_descriptor }

          it 'is not edugain compliant' do
            expect(subject).not_to be_edugain_compliant
          end
        end
      end
    end
  end

  describe '#destroy' do
    subject do
      create :entity_descriptor, :with_technical_contact, :with_sirtfi_contact,
             :with_publication_info, :with_entity_attribute,
             :with_refeds_rs_entity_category,
             :with_idp, :with_sp, :with_aa
    end

    it 'is successfully destroyed' do
      expect { subject.destroy }.not_to raise_error
    end
  end
end
