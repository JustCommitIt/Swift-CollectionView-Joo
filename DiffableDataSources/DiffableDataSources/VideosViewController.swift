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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import SafariServices

class VideosViewController: UICollectionViewController {
  // MARK: - Properties
//  private var videoList = Video.allVideos
  private var sections = Section.allSections
  private var searchController = UISearchController(searchResultsController: nil)
  private lazy var dataSource = makeDataSource()

  // MARK: - Value Types
  typealias DataSource = UICollectionViewDiffableDataSource<Section, Video>
  typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Video>
  
  // MARK: - Life Cycles
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    configureSearchController()
    configureLayout()
    applySnapshot(animatingDifferences: false)
  }
  
  // MARK: - Functions
  func applySnapshot(animatingDifferences: Bool = true) {
    var snapshot = Snapshot()
    snapshot.appendSections(sections)
    sections.forEach { section in
      snapshot.appendItems(section.videos, toSection: section)
    }
    dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
  }
  func makeDataSource() -> DataSource {
    let dataSource = DataSource(
      collectionView: collectionView,
      cellProvider: { (collectionView, indexPath, video) -> UICollectionViewCell? in
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as? VideoCollectionViewCell
        cell?.video = video
        return cell
    })
    // 1
    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
      // 2
      guard kind == UICollectionView.elementKindSectionHeader else {
        return nil
      }
      // 3
      let view = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: SectionHeaderReusableView.reuseIdentifier,
        for: indexPath) as? SectionHeaderReusableView
      // 4
      let section = self.dataSource.snapshot()
        .sectionIdentifiers[indexPath.section]
      view?.titleLabel.text = section.title
      return view
    }
    return dataSource
  }
}

// MARK: - UICollectionViewDataSource
extension VideosViewController {
//  override func collectionView(
//    _ collectionView: UICollectionView,
//    numberOfItemsInSection section: Int
//  ) -> Int {
//    return videoList.count
//  }
  
//  override func collectionView(
//    _ collectionView: UICollectionView,
//    cellForItemAt indexPath: IndexPath
//  ) -> UICollectionViewCell {
//    let video = videoList[indexPath.row]
//    guard let cell = collectionView.dequeueReusableCell(
//      withReuseIdentifier: "VideoCollectionViewCell",
//      for: indexPath) as? VideoCollectionViewCell else { fatalError() }
//    cell.video = video
//    return cell
//  }
}

// MARK: - UICollectionViewDelegate
extension VideosViewController {
  override func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    guard let video = dataSource.itemIdentifier(for: indexPath) else {
      return
    }
//    let video = videoList[indexPath.row]
    guard let link = video.link else {
      print("Invalid link")
      return
    }
    let safariViewController = SFSafariViewController(url: link)
    present(safariViewController, animated: true, completion: nil)
  }
}

// MARK: - UISearchResultsUpdating Delegate
extension VideosViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    sections = filteredSections(for: searchController.searchBar.text)
//    collectionView.reloadData()
    applySnapshot()
  }

  func filteredSections(for queryOrNil: String?) -> [Section] {
    let sections = Section.allSections

    guard
      let query = queryOrNil,
      !query.isEmpty
      else {
        return sections
    }

    return sections.filter { section in
      var matches = section.title.lowercased().contains(query.lowercased())
      for video in section.videos {
        if video.title.lowercased().contains(query.lowercased()) {
          matches = true
          break
        }
      }
      return matches
    }
  }
  
  func configureSearchController() {
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search Videos"
    navigationItem.searchController = searchController
    definesPresentationContext = true
  }
}
// MARK: - Layout Handling
extension VideosViewController {
  private func configureLayout() {
    collectionView.register(
      SectionHeaderReusableView.self ,
      forSupplementaryViewOfKind: UICollectionView .elementKindSectionHeader,
      withReuseIdentifier: SectionHeaderReusableView .reuseIdentifier
    )
    collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
      let isPhone = layoutEnvironment.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiom.phone
      let size = NSCollectionLayoutSize(
        widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
        heightDimension: NSCollectionLayoutDimension.absolute(isPhone ? 280 : 250)
      )
      let itemCount = isPhone ? 1 : 3
      let item = NSCollectionLayoutItem(layoutSize: size)
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: itemCount)
      let section = NSCollectionLayoutSection(group: group)
      section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
      section.interGroupSpacing = 10
      // Supplementary header view setup
      let headerFooterSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(20)
      )
      let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
        layoutSize: headerFooterSize,
        elementKind: UICollectionView.elementKindSectionHeader,
        alignment: .top
      )
      section.boundarySupplementaryItems = [sectionHeader]
      return section
    })
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { context in
      self.collectionView.collectionViewLayout.invalidateLayout()
    }, completion: nil)
  }
}

// MARK: - SFSafariViewControllerDelegate Implementation
extension VideosViewController: SFSafariViewControllerDelegate {
  func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    controller.dismiss(animated: true, completion: nil)
  }
}
