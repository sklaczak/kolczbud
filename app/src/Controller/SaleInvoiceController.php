<?php

namespace App\Controller;

use App\Entity\Invoice;
use App\Repository\InvoiceRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/invoices/sale')]
class SaleInvoiceController extends AbstractController
{
    #[Route('/', name: 'sale_invoice_list', methods: ['GET'])]
    public function list(InvoiceRepository $repo): Response
    {
        return $this->render('invoice/sale/list.html.twig', [
            'invoices' => $repo->findBy(['type' => 'sale']),
        ]);
    }

    #[Route('/new', name: 'sale_invoice_new', methods: ['GET', 'POST'])]
    public function new(Request $request, EntityManagerInterface $em): Response
    {
        $invoice = new Invoice();

        if ($request->isMethod('POST')) {
            $this->handleForm($invoice, $request);
            $em->persist($invoice);
            $em->flush();

            $this->addFlash('success', 'Faktura została dodana.');
            return $this->redirectToRoute('invoice_list');
        }

        return $this->render('invoice/sale/form.html.twig', [
            'invoice' => $invoice,
            'mode' => 'create',
        ]);
    }

    #[Route('/{id}/edit', name: 'sale_invoice_edit', methods: ['GET', 'POST'])]
    public function edit(Invoice $invoice, Request $request, EntityManagerInterface $em): Response
    {
        if ($request->isMethod('POST')) {
            $this->handleForm($invoice, $request);
            $em->flush();

            $this->addFlash('success', 'Faktura została zaktualizowana.');
            return $this->redirectToRoute('invoice_list');
        }

        return $this->render('invoice/cost/form.html.twig', [
            'invoice' => $invoice,
            'mode' => 'edit',
        ]);
    }

    #[Route('/{id}/delete', name: 'sale_invoice_delete', methods: ['POST'])]
    public function delete(Invoice $invoice, EntityManagerInterface $em): Response
    {
        $em->remove($invoice);
        $em->flush();

        $this->addFlash('success', 'Faktura została usunięta.');
        return $this->redirectToRoute('invoice_list');
    }

    private function handleForm(Invoice $invoice, Request $request): void
    {
        $number = $request->request->get('number');
        $customerName = $request->request->get('customerName');
        $amount = $request->request->get('amount');
        $status = $request->request->get('status');
        $issuedAt = $request->request->get('issuedAt');
        $dueDate = $request->request->get('dueDate');

        $invoice->setNumber($number);
        $invoice->setCustomerName($customerName);
        $invoice->setAmount($amount);
        $invoice->setStatus($status);

        $type = $request->request->get('type');

        if ($type && in_array($type, ['sale', 'cost'], true)) {
            $invoice->setType(InvoiceType::from($type));
        }

        $issuedAtDate = \DateTimeImmutable::createFromFormat('Y-m-d', $issuedAt) ?: new \DateTimeImmutable();
        $invoice->setIssuedAt($issuedAtDate);

        if ($dueDate) {
            $dueDateDate = \DateTimeImmutable::createFromFormat('Y-m-d', $dueDate);
            $invoice->setDueDate($dueDateDate ?: null);
        } else {
            $invoice->setDueDate(null);
        }
    }
}
