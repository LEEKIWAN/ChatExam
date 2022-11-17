//
//  CollectionViewCell.swift
//  ChatLayoutExam
//
//  Created by 이기완 on 2022/11/17.
//

import UIKit
import DifferenceKit
import ChatLayout

public extension UICollectionView {

    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        onInterruptedReload: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil,
        setData: (C) -> Void
    ) {
        if case .none = window, let data = stagedChangeset.last?.data {
            setData(data)
            if let onInterruptedReload = onInterruptedReload {
                onInterruptedReload()
            } else {
                reloadData()
            }
            completion?(false)
            return
        }

        let dispatchGroup: DispatchGroup? = completion != nil
            ? DispatchGroup()
            : nil
        let completionHandler: ((Bool) -> Void)? = completion != nil
            ? { _ in
                dispatchGroup!.leave()
            }
            : nil

        for changeset in stagedChangeset {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                setData(data)
                if let onInterruptedReload = onInterruptedReload {
                    onInterruptedReload()
                } else {
                    reloadData()
                }
                completion?(false)
                return
            }

            performBatchUpdates({
                setData(changeset.data)
                dispatchGroup?.enter()

                if !changeset.sectionDeleted.isEmpty {
                    deleteSections(IndexSet(changeset.sectionDeleted))
                }

                if !changeset.sectionInserted.isEmpty {
                    insertSections(IndexSet(changeset.sectionInserted))
                }

                if !changeset.sectionUpdated.isEmpty {
                    reloadSections(IndexSet(changeset.sectionUpdated))
                }

                for (source, target) in changeset.sectionMoved {
                    moveSection(source, toSection: target)
                }

                if !changeset.elementDeleted.isEmpty {
                    deleteItems(at: changeset.elementDeleted.map {
                        IndexPath(item: $0.element, section: $0.section)
                    })
                }

                if !changeset.elementInserted.isEmpty {
                    insertItems(at: changeset.elementInserted.map {
                        IndexPath(item: $0.element, section: $0.section)
                    })
                }

                if !changeset.elementUpdated.isEmpty {
                    reloadItems(at: changeset.elementUpdated.map {
                        IndexPath(item: $0.element, section: $0.section)
                    })
                }

                for (source, target) in changeset.elementMoved {
                    moveItem(at: IndexPath(item: source.element, section: source.section), to: IndexPath(item: target.element, section: target.section))
                }
            }, completion: completionHandler)
        }
        dispatchGroup?.notify(queue: .main) {
            completion!(true)
        }
    }

}

extension StagedChangeset {

    // DifferenceKit splits different type of actions into the different change sets to avoid the limitations of UICollectionView
    // But it may lead to the situations that `UICollectionViewLayout` doesnt know what change will happen next within the single portion
    // of changes. As we know that at least insertions and deletions can be processed together, we fix that in the StagedChangeset we got from
    // DifferenceKit.
    func flattenIfPossible() -> StagedChangeset {
        if count == 2,
           self[0].sectionChangeCount == 0,
           self[1].sectionChangeCount == 0,
           self[0].elementDeleted.count == self[0].elementChangeCount,
           self[1].elementInserted.count == self[1].elementChangeCount {
            return StagedChangeset(arrayLiteral: Changeset(data: self[1].data, elementDeleted: self[0].elementDeleted, elementInserted: self[1].elementInserted))
        }
        return self
    }

}




/// Custom implementation of `UICollectionViewLayoutAttributes`
public final class ChatLayoutAttributes: UICollectionViewLayoutAttributes {

    /// Alignment of the current item. Can be changed within `UICollectionViewCell.preferredLayoutAttributesFitting(...)`
    public var alignment: ChatItemAlignment = .fullWidth

    /// `CollectionViewChatLayout`s additional insets setup using `ChatLayoutSettings`. Added for convenience.
    public internal(set) var additionalInsets: UIEdgeInsets = .zero

    /// `UICollectionView`s frame size. Added for convenience.
    public internal(set) var viewSize: CGSize = .zero

    /// `UICollectionView`s adjusted content insets. Added for convenience.
    public internal(set) var adjustedContentInsets: UIEdgeInsets = .zero

    /// `CollectionViewChatLayout`s visible bounds size excluding `adjustedContentInsets`. Added for convenience.
    public internal(set) var visibleBoundsSize: CGSize = .zero

    /// `CollectionViewChatLayout`s visible bounds size excluding `adjustedContentInsets` and `additionalInsets`. Added for convenience.
    public internal(set) var layoutFrame: CGRect = .zero

    #if DEBUG
    var id: UUID?
    #endif

    convenience init(kind: ItemKind, indexPath: IndexPath = IndexPath(item: 0, section: 0)) {
        switch kind {
        case .cell:
            self.init(forCellWith: indexPath)
        case .header:
            self.init(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: indexPath)
        case .footer:
            self.init(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: indexPath)
        }
    }

    /// Returns an exact copy of `ChatLayoutAttributes`.
    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ChatLayoutAttributes
        copy.viewSize = viewSize
        copy.alignment = alignment
        copy.layoutFrame = layoutFrame
        copy.additionalInsets = additionalInsets
        copy.visibleBoundsSize = visibleBoundsSize
        copy.adjustedContentInsets = adjustedContentInsets
        #if DEBUG
        copy.id = id
        #endif
        return copy
    }

    /// Returns a Boolean value indicating whether two `ChatLayoutAttributes` are considered equal.
    public override func isEqual(_ object: Any?) -> Bool {
        super.isEqual(object)
            && alignment == (object as? ChatLayoutAttributes)?.alignment
    }

    /// `ItemKind` represented by this attributes object.
    public var kind: ItemKind {
        switch (representedElementCategory, representedElementKind) {
        case (.cell, nil):
            return .cell
        case (.supplementaryView, .some(UICollectionView.elementKindSectionHeader)):
            return .header
        case (.supplementaryView, .some(UICollectionView.elementKindSectionFooter)):
            return .footer
        default:
            preconditionFailure("Unsupported element kind.")
        }
    }

    func typedCopy() -> ChatLayoutAttributes {
        guard let typedCopy = copy() as? ChatLayoutAttributes else {
            fatalError("Internal inconsistency.")
        }
        return typedCopy
    }

}


public protocol ContainerCollectionViewCellDelegate: AnyObject {

    /// Perform any clean up necessary to prepare the view for use again.
    func prepareForReuse()

    /// Allows to override the call of `ContainerCollectionViewCell`/`ContainerCollectionReusableView`
    /// `UICollectionReusableView.preferredLayoutAttributesFitting(...)` and make the layout calculations.
    ///
    /// **NB**: You must override it to avoid unnecessary autolayout calculations if you are providing exact cell size
    /// in `ChatLayoutDelegate.sizeForItem(...)` and return `layoutAttributes` without modifications.
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `CollectionViewChatLayout`
    /// - Returns: Modified `ChatLayoutAttributes` on nil if `UICollectionReusableView.preferredLayoutAttributesFitting(...)`
    ///            should be called instead.
    func preferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes) -> ChatLayoutAttributes?

    /// Allows to additionally modify `ChatLayoutAttributes` after the `UICollectionReusableView.preferredLayoutAttributesFitting(...)`
    /// call.
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `CollectionViewChatLayout`.
    /// - Returns: Modified `ChatLayoutAttributes`
    func modifyPreferredLayoutAttributesFitting(_ layoutAttributes: ChatLayoutAttributes)

    /// Apply the specified layout attributes to the view.
    /// Keep in mind that this method can be called multiple times.
    /// - Parameter layoutAttributes: `ChatLayoutAttributes` provided by `CollectionViewChatLayout`.
    func apply(_ layoutAttributes: ChatLayoutAttributes)

}


/// Represent item alignment in collection view layout
public enum ChatItemAlignment: Hashable {

    /// Should be aligned at the leading edge of the layout. That includes all the additional content offsets.
    case leading

    /// Should be aligned at the center of the layout.
    case center

    /// Should be aligned at the trailing edge of the layout.
    case trailing

    /// Should be aligned using the full width of the available content width.
    case fullWidth

}


public enum ItemKind: CaseIterable, Hashable {

    /// Header item
    case header

    /// Cell item
    case cell

    /// Footer item
    case footer

    init(_ elementKind: String) {
        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            self = .header
        case UICollectionView.elementKindSectionFooter:
            self = .footer
        default:
            preconditionFailure("Unsupported supplementary view kind.")
        }
    }

    /// Returns: `true` if this `ItemKind` is equal to `ItemKind.header` or `ItemKind.footer`
    public var isSupplementaryItem: Bool {
        switch self {
        case .cell:
            return false
        case .header, .footer:
            return true
        }
    }

    var supplementaryElementStringType: String {
        switch self {
        case .cell:
            preconditionFailure("Cell type is not a supplementary view.")
        case .header:
            return UICollectionView.elementKindSectionHeader
        case .footer:
            return UICollectionView.elementKindSectionFooter
        }
    }

}


extension UICollectionView {
    func scrollToLast(animated: Bool) {
        guard numberOfSections > 0 else {
            return
        }

        let lastSection = numberOfSections - 1

        guard numberOfItems(inSection: lastSection) > 0 else {
            return
        }

        let lastItemIndexPath = IndexPath(item: numberOfItems(inSection: lastSection) - 1, section: lastSection)
        scrollToItem(at: lastItemIndexPath, at: .bottom, animated: animated)
    }
    
    
    public func reloadDataAndKeepOffset() {
      // stop scrolling
      setContentOffset(contentOffset, animated: false)

      // calculate the offset and reloadData
      let beforeContentSize = contentSize
      reloadData()
      layoutIfNeeded()
      let afterContentSize = contentSize

      // reset the contentOffset after data is updated
      let newOffset = CGPoint(
        x: contentOffset.x + (afterContentSize.width - beforeContentSize.width),
        y: contentOffset.y + (afterContentSize.height - beforeContentSize.height))
      setContentOffset(newOffset, animated: false)
    }
}

