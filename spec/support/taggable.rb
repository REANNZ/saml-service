# frozen_string_literal: true

shared_examples 'a taggable model' do |tag_factory, association|
  let(:klass) { described_class.name.underscore.to_sym }

  def factory_args(tag_name, instance, association)
    factory_args = {}
    factory_args[:name] = tag_name
    factory_args[association] = instance
    factory_args
  end

  describe '#with_any_tag' do
    let(:tag_name) { Faker::Lorem.word }
    let(:instance) { create(klass) }

    subject { described_class.with_any_tag(tag_name) }

    it { is_expected.to eq([]) }

    context 'when an associated tag exists' do
      before do
        create(tag_factory,
               factory_args(tag_name, instance, association))
      end
      it {
        is_expected.to contain_exactly(instance)
        is_expected.to contain_exactly(an_instance_of(described_class))
      }
    end

    context "when a tag exists for multiple #{described_class.name}" do
      let!(:another_instance) { create(klass) }

      before do
        create(tag_factory, factory_args(tag_name, instance, association))
        create(tag_factory, factory_args(tag_name,
                                         another_instance, association))
      end
      it "should contain two instances of #{described_class}" do
        is_expected.to contain_exactly(instance, another_instance)
        expect(subject).to contain_exactly(an_instance_of(described_class),
                                           an_instance_of(described_class))
      end
    end

    context "with multiple tags existing for a #{described_class.name}" do
      let(:another_tag_name) { Faker::Lorem.characters }

      subject { described_class.with_any_tag([tag_name, another_tag_name]) }

      before do
        create(tag_factory, factory_args(tag_name, instance, association))
        create(tag_factory, factory_args(another_tag_name, instance,
                                         association))
      end

      it {
        is_expected.to contain_exactly(instance)
        is_expected.to contain_exactly(an_instance_of(described_class))
      }
    end

    context "with a tag amongst many #{described_class.name}" do
      let(:another_tag_name) { Faker::Lorem.characters }
      let!(:another_instance) { create(klass) }

      subject { described_class.with_any_tag(tag_name) }

      before do
        create(tag_factory, factory_args(tag_name, instance, association))
        create(tag_factory, factory_args(another_tag_name, another_instance,
                                         association))
      end

      it {
        is_expected.to contain_exactly(instance)
        is_expected.to contain_exactly(an_instance_of(described_class))
      }
    end
  end

  describe '#with_all_tags' do
    let(:tag_name) { Faker::Lorem.characters }
    let(:instance) { create(klass) }

    context 'with a single argument' do
      subject { described_class.with_all_tags(tag_name) }

      it { is_expected.to eq([]) }

      context "when a single #{described_class.name} association exists" do
        before do
          create(tag_factory, factory_args(tag_name, instance, association))
        end
        it {
          is_expected.to contain_exactly(instance)
          is_expected.to contain_exactly(an_instance_of(described_class))
        }
      end

      context "when multiple #{described_class.name} associations exists" do
        let!(:another_instance) { create(klass) }
        before do
          create(tag_factory, factory_args(tag_name, instance, association))
          create(tag_factory, factory_args(tag_name,
                                           another_instance, association))
        end
        it "should contain two instances of #{described_class}" do
          is_expected.to contain_exactly(instance, another_instance)
          expect(subject).to contain_exactly(an_instance_of(described_class),
                                             an_instance_of(described_class))
        end
      end
    end

    context 'with multiple arguments' do
      let(:another_tag_name) { Faker::Lorem.characters }

      subject { described_class.with_all_tags([tag_name, another_tag_name]) }

      it { is_expected.to eq([]) }

      context "with a #{described_class.name} associated with all tags" do
        before do
          create(tag_factory, factory_args(tag_name, instance, association))
          create(tag_factory, factory_args(another_tag_name, instance,
                                           association))
        end

        it {
          is_expected.to contain_exactly(instance)
          is_expected.to contain_exactly(an_instance_of(described_class))
        }
      end

      context "with a #{described_class.name} associated with one tag only" do
        before do
          create(tag_factory, factory_args(tag_name, instance, association))
        end

        it { is_expected.to eq([]) }
      end

      context "with a #{described_class.name} associated with no tags" do
        before do
          create(tag_factory, factory_args(Faker::Lorem.characters,
                                           instance, association))
        end

        it { is_expected.to eq([]) }
      end

      context "with many #{described_class.name} associated with all tags" do
        let!(:another_instance_1) { create(klass) }
        let!(:another_instance_2) { create(klass) }

        before do
          create(tag_factory, factory_args(tag_name, instance, association))
          create(tag_factory, factory_args(another_tag_name, instance,
                                           association))
          create(tag_factory, factory_args(tag_name, another_instance_1,
                                           association))
          create(tag_factory, factory_args(another_tag_name, another_instance_1,
                                           association))
          create(tag_factory, factory_args(tag_name, another_instance_2,
                                           association))
          create(tag_factory, factory_args(another_tag_name, another_instance_2,
                                           association))
        end

        it "should contain all #{described_class} instances" do
          expect(subject).to contain_exactly(instance, another_instance_1,
                                             another_instance_2)
          expect(subject).to contain_exactly(an_instance_of(described_class),
                                             an_instance_of(described_class),
                                             an_instance_of(described_class))
        end
      end
    end
  end
end
