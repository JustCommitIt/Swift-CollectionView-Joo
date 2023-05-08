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
  var adoptions = Set<Pet>()
  lazy var dataSource = makeDataSource()
  let categoryCellregistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
    var configuration = cell.defaultContentConfiguration()
    configuration.text = item.title
    cell.contentConfiguration = configuration
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
    let configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
    collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: configuration)
  }

  func makeDataSource() -> DataSource {
    return DataSource(collectionView: collectionView) {
      collectionView, indexPath, item -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(
        using: self.categoryCellregistration, for: indexPath, item: item)
    }
  }

  func applyInitialSnapshots() {
    var categorySnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    let categories = Pet.Category.allCases.map { category in
      return Item(title: String(describing: category))
    }
    categorySnapshot.appendSections([.availablePets])
    categorySnapshot.appendItems(categories, toSection: .availablePets)
    dataSource.apply(categorySnapshot, animatingDifferences: false)
  }
}

// MARK: - CollectionView Cells
extension PetExplorerViewController {
}

// MARK: - UICollectionViewDelegate
extension PetExplorerViewController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
  }
}
