/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class PetExplorerViewController: UICollectionViewController {
  // MARK: - Properties
  static var adoptions = Set<Pet>()
  lazy var dataSource = makeDataSource()
  let categoryCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
    var configuration = cell.defaultContentConfiguration()
    configuration.text = item.title
    cell.contentConfiguration = configuration
    let options = UICellAccessory.OutlineDisclosureOptions(style: .header)
    let disclosureAccessory = UICellAccessory.outlineDisclosure(options: options)
    cell.accessories = [disclosureAccessory]
  }
  let petCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
    guard let pet = item.pet else {
      return
    }
    var configuration = cell.defaultContentConfiguration()
    configuration.text = pet.name
    configuration.secondaryText = "\(pet.age)세"
    configuration.image = UIImage(named: pet.imageName)
    configuration.imageProperties.maximumSize = CGSize(width: 40, height: 40)
    cell.contentConfiguration = configuration

    if PetExplorerViewController.isAdopted(pet: pet) {
      var backgroundConfig = UIBackgroundConfiguration.listPlainCell()
      backgroundConfig.backgroundColor = .systemBlue
      backgroundConfig.cornerRadius = 5
      backgroundConfig.backgroundInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
      cell.backgroundConfiguration = backgroundConfig
    }

    cell.accessories = [.disclosureIndicator()]
  }
  let adoptedPetCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
    guard let pet = item.pet else {
      return
    }
    var configuration = cell.defaultContentConfiguration()
    configuration.text = "Your pet: \(pet.name)"
    configuration.secondaryText = "\(pet.age) years old"
    configuration.image = UIImage(named: pet.imageName)
    configuration.imageProperties.maximumSize = CGSize(width: 40, height: 40)
    cell.contentConfiguration = configuration
    cell.accessories =  [.disclosureIndicator()]
  }


  static func isAdopted(pet: Pet) -> Bool {
    PetExplorerViewController.adoptions.contains(pet)
  }

  // MARK: - Types
  enum Section: Int, CaseIterable, Hashable {
    case availablePets
    case adoptedPets
  }
  typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>

  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "Pet Explorer"
    configureLayout()
    applyInitialSnapshots()
  }

  // MARK: - Functions
  func configureLayout() {
//    let configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
//    collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: configuration)
    // 1
    let provider =
      {(_: Int, layoutEnv: NSCollectionLayoutEnvironment) ->
        NSCollectionLayoutSection? in
      // 2
      let configuration = UICollectionLayoutListConfiguration(
        appearance: .grouped)
      // 3
      return NSCollectionLayoutSection.list(
        using: configuration,
        layoutEnvironment: layoutEnv)
    }
    // 4
    collectionView.collectionViewLayout =
      UICollectionViewCompositionalLayout(sectionProvider: provider)

  }

  func makeDataSource() -> DataSource {
    return DataSource(collectionView: collectionView) {
      collectionView, indexPath, item -> UICollectionViewCell? in
      if item.pet != nil {
        guard let section = Section(rawValue: indexPath.section) else {
          return nil
        }
        switch section {
        case .availablePets:
          return collectionView.dequeueConfiguredReusableCell(
            using: self.petCellRegistration, for: indexPath, item: item)
        case .adoptedPets:
          return collectionView.dequeueConfiguredReusableCell(
            using: self.adoptedPetCellRegistration, for: indexPath, item: item)
        }
      } else {
        return collectionView.dequeueConfiguredReusableCell(
          using: self.categoryCellRegistration, for: indexPath, item: item)
      }
    }
  }

  func updateDataSource(for pet: Pet) {
    var snapshot = dataSource.snapshot()
    let items = snapshot.itemIdentifiers
    let petItem = items.first { item in
      item.pet == pet
    }
    if let petItem = petItem {
      snapshot.reloadItems([petItem])
      dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
    }
  }

  func applyInitialSnapshots() {
    // 1
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    // 2
    snapshot.appendSections(Section.allCases)
    // 3
    dataSource.apply(snapshot, animatingDifferences: false)

    var categorySnapshot = NSDiffableDataSourceSectionSnapshot<Item>()

    for category in Pet.Category.allCases {
      let categoryItem = Item(title: String(describing: category))
      categorySnapshot.append([categoryItem])
      let petItems = category.pets.map { Item(pet: $0, title: $0.name) }
      categorySnapshot.append(petItems, to: categoryItem)
    }
    let categories = Pet.Category.allCases.map { category in
      return Item(title: String(describing: category))
    }
    dataSource.apply(categorySnapshot, to: .availablePets, animatingDifferences: false)
  }
}

// MARK: - CollectionView Cells
extension PetExplorerViewController {


}

// MARK: - UICollectionViewDelegate
extension PetExplorerViewController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let item = dataSource.itemIdentifier(for: indexPath) else {
      collectionView.deselectItem(at: indexPath, animated: true)
      return
    }
    guard let pet = item.pet else {
      return
    }
    pushDetailForPet(pet, withAdoptionStatus: PetExplorerViewController.adoptions.contains(pet))
  }

  func pushDetailForPet(_ pet: Pet, withAdoptionStatus isAdopted: Bool) {
    let storyboard = UIStoryboard(name: "Main", bundle: .main)
    let petDetailViewController =
      storyboard.instantiateViewController(identifier: "PetDetailViewController") { coder in
        return PetDetailViewController(coder: coder, pet: pet)
      }
    petDetailViewController.delegate = self
    petDetailViewController.isAdopted = isAdopted
    navigationController?.pushViewController(petDetailViewController, animated: true)
  }
}

// MARK: - PetDetailViewControllerDelegate
extension PetExplorerViewController: PetDetailViewControllerDelegate {
  func petDetailViewController(_ petDetailViewController: PetDetailViewController, didAdoptPet pet: Pet) {
    PetExplorerViewController.adoptions.insert(pet)
    updateDataSource(for: pet)
    // 1
    var adoptedPetsSnapshot = dataSource.snapshot(for: .adoptedPets)
    // 2
    let newItem = Item(pet: pet, title: pet.name)
    // 3
    adoptedPetsSnapshot.append([newItem])
    // 4
    dataSource.apply(
      adoptedPetsSnapshot,
      to: .adoptedPets,
      animatingDifferences: true,
      completion: nil)

  }
}
