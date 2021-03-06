//
//  GSideMenuViewController.m
//  GenShelf
//
//  Created by Gen on 16/2/19.
//  Copyright © 2016年 AirRaidClub. All rights reserved.
//

#import "GSideMenuController.h"
#import "GSideCoverView.h"
#import "GTween.h"
#import "GShadowView.h"


#define MENU_WIDTH  220

static NSMutableArray<GSideMenuController*> *_menuControllers;

@implementation GSideMenuItem

+ (id)itemWithController:(UIViewController *)controller {
    GSideMenuItem *item = [[GSideMenuItem alloc] init];
    item.controller = controller;
    item.title = controller.title;
    return item;
}

+ (id)itemWithController:(UIViewController *)controller image:(UIImage *)image {
    GSideMenuItem *item = [[GSideMenuItem alloc] init];
    item.controller = controller;
    item.title = controller.title;
    item.image = image;
    return item;
}

+ (id)itemWithTitle:(NSString *)title block:(GSideMenuItemBlock)block {
    GSideMenuItem *item = [[GSideMenuItem alloc] init];
    item.title = title;
    item.block = block;
    return item;
}

+ (id)itemWithTitle:(NSString *)title image:(UIImage *)image block:(GSideMenuItemBlock)block {
    GSideMenuItem *item = [[GSideMenuItem alloc] init];
    item.title = title;
    item.image = image;
    item.block = block;
    return item;
}

@end

@interface GSideMenuController ()<UITableViewDelegate, UITableViewDataSource> {
    UITableView *_tableView;
    UIView *_currentView;
    UIView *_contentView;
    GSideCoverView  *_coverView;
    GShadowView *_shadowView;
    BOOL _isOpen;
}

- (void)updateView;

@end

@implementation GSideMenuController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _selectedIndex = 0;
        _currentView = NULL;
        _isOpen = NO;
        
        if (!_menuControllers) {
            _menuControllers = [[NSMutableArray alloc] init];
        }
        [_menuControllers addObject:self];
        
        _navController = [[UINavigationController alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_menuControllers removeObject:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    CGRect bounds = self.view.bounds;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, MENU_WIDTH,
                                                               bounds.size.height)
                                              style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    
    _contentView = [[UIView alloc] initWithFrame:bounds];
    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.layer.shadowColor = [[UIColor blackColor] CGColor];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _shadowView = [[GShadowView alloc] initWithFrame:CGRectMake(-12, 0, 12, bounds.size.height)];
    _shadowView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [_contentView addSubview:_shadowView];
    
    _coverView = [[GSideCoverView alloc] initWithFrame:bounds];
    _coverView.userInteractionEnabled = YES;
    __weak GSideMenuController *that = self;
    _coverView.moveBlock = ^(CGPoint point) {
        [that touchMove:point.x];
    };
    _coverView.endBlock = ^(CGPoint p) {
        [that touchEnd];
    };
    [self addChildViewController:_navController];
    [_contentView addSubview:_navController.view];
    [_contentView addSubview:_coverView];
    [_coverView setHidden:YES];
    [self.view addSubview:_contentView];
    
    [self updateView];
}

- (void)setItems:(NSArray<GSideMenuItem *> *)items {
    if (_items != items) {
        _items = items;
        if ([self isViewLoaded]) {
            [self updateView];
            [_tableView reloadData];
        }
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (_selectedIndex != selectedIndex) {
        [self sideMenuSelect:selectedIndex];
        GSideMenuItem *item = [_items objectAtIndex:selectedIndex];
        if (item.controller) {
            NSUInteger uidx = _selectedIndex;
            _selectedIndex = selectedIndex;
            [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:uidx
                                                                    inSection:0],
                                                 [NSIndexPath indexPathForRow:_selectedIndex
                                                                    inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
            [self updateView];
        }else if (item.block){
            item.block();
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_items) {
        return _items.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"NormalCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    NSInteger row = indexPath.row;
    GSideMenuItem *item = [_items objectAtIndex:row];
    cell.textLabel.text = item.title;
    cell.imageView.image = item.image;
    if (row == _selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath.row;
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [self performSelector:@selector(unselect:)
                   withObject:cell
                   afterDelay:0];
    }
}

- (void)unselect:(UITableViewCell *)cell {
    [cell setSelected:NO animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    _tableView.frame = CGRectMake(0, 0, MENU_WIDTH,
                                  self.view.bounds.size.height);
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.navController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _tableView.frame = CGRectMake(0, 0, MENU_WIDTH,
                                      self.view.bounds.size.height);
    } completion:nil];
    [self.navController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)updateView {
    if (_selectedIndex >= _items.count) _selectedIndex = _items.count - 1;
    if (_currentView) {
        [_currentView removeFromSuperview];
        GSideMenuItem *item = [_items objectAtIndex:_selectedIndex];
        if (item.controller) {
            [_navController setViewControllers:@[item.controller]
                                      animated:YES];
        }
    }else {
        GSideMenuItem *item = [_items objectAtIndex:_selectedIndex];
        if (item.controller) {
            [_navController setViewControllers:@[item.controller]
                                      animated:YES];
        }
    }
}

- (void)openMenu {
    _isOpen = YES;
    [self.view insertSubview:_tableView atIndex:0];
    
    [_coverView setHidden:NO];
    [_contentView bringSubviewToFront:_coverView];
    
    [GTween cancel:_contentView];
    GTween *tween = [GTween tween:_contentView
                         duration:0.4
                             ease:[GEaseCubicOut class]];
    CGRect bounds = self.view.bounds;
    [tween addProperty:[GTweenCGRectProperty property:@"frame"
                                                 from:_contentView.frame
                                                   to:CGRectMake(MENU_WIDTH, 0,
                                                                 bounds.size.width,
                                                                 bounds.size.height)]];
    [tween.onUpdate addTarget:self
                       action:@selector(updateTableScale)
                         with:NULL];
    [tween start];
}

- (void)closeMenu {
    _isOpen = NO;
    [_coverView setHidden:YES];
    
    [GTween cancel:_contentView];
    GTween *tween = [GTween tween:_contentView
                         duration:0.4
                             ease:[GEaseCubicOut class]];
    CGRect bounds = self.view.bounds;
    [tween addProperty:[GTweenCGRectProperty property:@"frame"
                                                 from:_contentView.frame
                                                   to:CGRectMake(0, 0,
                                                                 bounds.size.width,
                                                                 bounds.size.height)]];
    [tween.onUpdate addTarget:self
                       action:@selector(updateTableScale)
                         with:NULL];
    [tween start];
    [tween.onUpdate addBlock:^{
        [self updateTableScale];
    }];
    [tween.onComplete addBlock:^{
        [_tableView removeFromSuperview];
    }];
}

- (void)touchMove:(CGFloat)offset {
    if (!_tableView.superview) {
        [self.view insertSubview:_tableView atIndex:0];
    }
    CGRect frame = _contentView.frame;
    frame.origin.x = MIN(MAX(0, frame.origin.x + offset), MENU_WIDTH);
    [self updateTableScale];
    _contentView.frame = frame;
}

- (void)updateTableScale {
    float p = _contentView.frame.origin.x / MENU_WIDTH;
    p = p * 0.3 + 0.7;
    _tableView.layer.transform = CATransform3DMakeScale(p, p, p);
}

- (void)touchEnd {
    CGRect frame = _contentView.frame;
    if (_isOpen) {
        if (frame.origin.x < MENU_WIDTH*3.0/4.0) {
            [self closeMenu];
        }else {
            [self openMenu];
        }
    }else {
        if (frame.origin.x > MENU_WIDTH/4) {
            [self openMenu];
        }else {
            [self closeMenu];
        }
    }
}

- (void)sideMenuSelect:(NSUInteger)index {}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (_navController.visibleViewController) {
        return _navController.visibleViewController.supportedInterfaceOrientations;
    }
    if (_navController.topViewController) {
        return _navController.topViewController.supportedInterfaceOrientations;
    }
    return _navController.supportedInterfaceOrientations;
}

- (BOOL)shouldAutorotate
{
    if (_navController.visibleViewController) {
        return _navController.visibleViewController.shouldAutorotate;
    }
    if(_navController.visibleViewController)
    {
        return _navController.visibleViewController.shouldAutorotate;
    }
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (_navController.visibleViewController) {
        return _navController.visibleViewController.preferredInterfaceOrientationForPresentation;
    }
    if(_navController.visibleViewController)
    {
        return _navController.visibleViewController.preferredInterfaceOrientationForPresentation;
    }
    return _navController.preferredInterfaceOrientationForPresentation;
}

@end

@implementation UIViewController (GSideMenuController)

- (GSideMenuController *)sideMenuController {
    UIViewController *ctrl = self.parentViewController;
    while (ctrl) {
        if ([ctrl isKindOfClass:[GSideMenuController class]]) {
            return (GSideMenuController*)ctrl;
        }
        ctrl = ctrl.parentViewController;
    }
    return NULL;
}

@end
